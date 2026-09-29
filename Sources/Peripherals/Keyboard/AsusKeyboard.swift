import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.ghelper.mac", category: "AsusKeyboard")

public enum KeyboardLightingMode: UInt8, CaseIterable, Identifiable {
    case `static` = 0
    case breathing = 1
    case colorCycle = 2
    case reactive = 3
    case wave = 4
    case ripple = 5
    case starryNight = 6
    case quicksand = 7
    case current = 8
    case rainDrop = 9

    public var id: UInt8 { rawValue }

    public var displayName: String {
        switch self {
        case .static: return "Static"
        case .breathing: return "Breathing"
        case .colorCycle: return "Color Cycle"
        case .reactive: return "Reactive"
        case .wave: return "Wave"
        case .ripple: return "Ripple"
        case .starryNight: return "Starry Night"
        case .quicksand: return "Quicksand"
        case .current: return "Current"
        case .rainDrop: return "Rain Drop"
        }
    }
}

public enum KeyboardSpeed: UInt8, CaseIterable, Identifiable {
    case slow = 0
    case medium = 1
    case fast = 2

    public var id: UInt8 { rawValue }
    public var displayName: String {
        switch self {
        case .slow: return "Slow"
        case .medium: return "Medium"
        case .fast: return "Fast"
        }
    }

    public var packetValue: UInt8 {
        switch self {
        case .slow: return 0xE1
        case .medium: return 0xEB
        case .fast: return 0xF5
        }
    }
}

open class AsusKeyboard: ObservableObject, AsusPeripheral, @unchecked Sendable {
    public let id: String
    public let session: HIDDeviceSession
    public let reportId: UInt8
    public let metadata: KeyboardMetadata
    public let peripheralType: PeripheralType = .keyboard

    public var displayName: String { metadata.displayName }

    // MARK: - Published State
    @Published public var isReady: Bool = false
    @Published public var battery: Int = 0
    @Published public var isCharging: Bool = false
    @Published public var sleepTimer: Int = 3 // minutes

    // Lighting
    @Published public var lightingMode: KeyboardLightingMode = .static
    @Published public var lightingBrightness: Int = 75
    @Published public var lightingSpeed: KeyboardSpeed = .medium
    @Published public var lightingColor: Color = .red

    // OLED Screen (ROG Azoth / Flare II Animate)
    @Published public var oledEnabled: Bool = true
    @Published public var oledBrightness: Int = 80
    @Published public var oledAnimation: Int = 0

    private let workQueue = DispatchQueue(label: "com.ghelper.mac.keyboard.queue", qos: .userInitiated)

    public init(session: HIDDeviceSession, id: String, metadata: KeyboardMetadata) {
        self.session = session
        self.id = id
        self.metadata = metadata
        self.reportId = metadata.reportId
    }

    // MARK: - Synchronization

    public func synchronizeDevice() {
        workQueue.async {
            var ready = false
            if self.metadata.hasBattery {
                if let (bat, chg) = self.readBattery() {
                    DispatchQueue.main.async {
                        self.battery = bat
                        self.isCharging = chg
                    }
                    ready = true
                }
            } else {
                ready = true
            }

            self.readLighting()

            DispatchQueue.main.async {
                self.isReady = ready
            }
        }
    }

    public func pollBattery() {
        guard metadata.hasBattery else { return }
        workQueue.async {
            guard let (bat, chg) = self.readBattery() else { return }
            DispatchQueue.main.async {
                self.battery = bat
                self.isCharging = chg
                self.isReady = true
            }
        }
    }

    // MARK: - Battery & Power

    public func readBattery() -> (battery: Int, charging: Bool)? {
        guard let response = session.writeForResponse(packet: [reportId, 0x12, 0x01]), response.count >= 10 else {
            return nil
        }
        guard response[1] == 0x12 && response[2] == 0x01 else { return nil }
        let bat = Int(response[5])
        let chg = response[9] == 1
        return (max(0, min(100, bat)), chg)
    }

    public func applyEnergySettings() {
        guard metadata.hasBattery else { return }
        workQueue.async {
            let sleepByte = UInt8(clamping: self.sleepTimer)
            let packet: [UInt8] = [self.reportId, 0x51, 0x37, 0x00, 0x00, sleepByte, 0x00, 20]
            _ = self.session.writeForResponse(packet: packet)
        }
    }

    // MARK: - Lighting

    public func readLighting() {
        guard let response = session.writeForResponse(packet: [reportId, 0x12, 0x02]), response.count >= 12 else {
            return
        }
        let modeByte = response[3]
        let brightness = Int(response[6])
        let r = Double(response[10]) / 255.0
        let g = Double(response[11]) / 255.0
        let b = Double(response[12]) / 255.0

        DispatchQueue.main.async {
            if let mode = KeyboardLightingMode(rawValue: modeByte) {
                self.lightingMode = mode
            }
            self.lightingBrightness = max(0, min(100, brightness))
            self.lightingColor = Color(red: r, green: g, blue: b)
        }
    }

    public func applyLighting() {
        workQueue.async {
            let (r, g, b) = self.colorToRGB(self.lightingColor)
            let mode = self.lightingMode.rawValue
            let bright = UInt8(clamping: self.lightingBrightness)
            let speed = self.lightingSpeed.packetValue

            var packet: [UInt8] = [
                self.reportId, 0x51, 0x2C, mode, 0x00, speed, bright, 0x00, 0x00, 0x02,
                r, g, b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            ]
            if self.lightingMode == .wave || self.lightingMode == .ripple {
                packet[7] = 1 // Random color for wave/ripple
            }
            _ = self.session.writeForResponse(packet: packet)
            _ = self.session.writeForResponse(packet: [self.reportId, 0x50, 0x55])
        }
    }

    // MARK: - OLED Display (ROG Azoth / Strix Flare II Animate)

    public func applyOledSettings() {
        guard metadata.hasOled else { return }
        workQueue.async {
            // Enable / Disable OLED
            _ = self.session.writeForResponse(packet: [self.reportId, 0x69, 0x00, 0x00, 0x00, self.oledEnabled ? 1 : 0])

            // Brightness
            let bright = UInt8(clamping: self.oledBrightness)
            _ = self.session.writeForResponse(packet: [self.reportId, 0x69, 0x01, 0x00, 0x00, bright])

            // Animation Index
            let anim = UInt8(clamping: self.oledAnimation)
            _ = self.session.writeForResponse(packet: [self.reportId, 0x6A, 0x01, 0x00, 0x00, anim])
        }
    }

    private func colorToRGB(_ color: Color) -> (UInt8, UInt8, UInt8) {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.red
        return (
            UInt8(clamping: Int(nsColor.redComponent * 255)),
            UInt8(clamping: Int(nsColor.greenComponent * 255)),
            UInt8(clamping: Int(nsColor.blueComponent * 255))
        )
    }
}
