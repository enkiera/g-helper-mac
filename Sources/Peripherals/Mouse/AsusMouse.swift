import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.ghelper.mac", category: "AsusMouse")

public enum MouseLightingMode: UInt8, CaseIterable, Identifiable {
    case off = 0xF0
    case `static` = 0x00
    case breathing = 0x01
    case colorCycle = 0x02
    case rainbow = 0x03
    case batteryState = 0x06

    public var id: UInt8 { rawValue }

    public var displayName: String {
        switch self {
        case .off: return "Off"
        case .static: return "Static"
        case .breathing: return "Breathing"
        case .colorCycle: return "Color Cycle"
        case .rainbow: return "Rainbow"
        case .batteryState: return "Battery State"
        }
    }
}

public enum MousePollingRate: Int, CaseIterable, Identifiable {
    case hz125 = 125
    case hz250 = 250
    case hz500 = 500
    case hz1000 = 1000
    case hz2000 = 2000
    case hz4000 = 4000
    case hz8000 = 8000

    public var id: Int { rawValue }
    public var displayName: String { "\(rawValue) Hz" }

    public var packetValue: UInt8 {
        switch self {
        case .hz125: return 0
        case .hz250: return 1
        case .hz500: return 2
        case .hz1000: return 3
        case .hz2000: return 4
        case .hz4000: return 5
        case .hz8000: return 6
        }
    }

    public static func fromPacket(value: UInt8) -> MousePollingRate {
        switch value {
        case 0: return .hz125
        case 1: return .hz250
        case 2: return .hz500
        case 3: return .hz1000
        case 4: return .hz2000
        case 5: return .hz4000
        case 6: return .hz8000
        default: return .hz1000
        }
    }
}

open class AsusMouse: ObservableObject, AsusPeripheral, @unchecked Sendable {
    public let id: String
    public let session: HIDDeviceSession
    public let reportId: UInt8
    public let metadata: MouseMetadata
    public let peripheralType: PeripheralType = .mouse

    public var displayName: String { metadata.displayName }

    // MARK: - Published State
    @Published public var isReady: Bool = false
    @Published public var battery: Int = 0
    @Published public var isCharging: Bool = false
    @Published public var sleepTimer: Int = 3 // minutes
    @Published public var lowBatteryWarning: Int = 20

    // DPI Settings (Stages 1-4)
    @Published public var activeDpiStage: Int = 1 // 1-indexed (1 to 4)
    @Published public var dpiStages: [Int] = [400, 800, 1600, 3200]
    @Published public var dpiColors: [Color] = [.red, .purple, .blue, .green]

    // Performance
    @Published public var pollingRate: MousePollingRate = .hz1000
    @Published public var angleSnapping: Bool = false
    @Published public var liftOffDistance: Int = 0 // 0 = Low, 1 = High
    @Published public var debounceTime: Int = 12 // ms

    // Lighting
    @Published public var lightingMode: MouseLightingMode = .static
    @Published public var lightingBrightness: Int = 50
    @Published public var lightingColor: Color = .red

    private let workQueue = DispatchQueue(label: "com.ghelper.mac.mouse.queue", qos: .userInitiated)

    public init(session: HIDDeviceSession, id: String, metadata: MouseMetadata) {
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

            self.readDpi()
            self.readPerformance()
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
        guard let response = session.writeForResponse(packet: [reportId, 0x12, 0x07]), response.count >= 7 else {
            return nil
        }
        guard response[1] == 0x12 && response[2] == 0x07 else { return nil }
        let bat = Int(response[5])
        let chg = response[6] != 0
        return (max(0, min(100, bat)), chg)
    }

    public func applyEnergySettings() {
        workQueue.async {
            let powerOffByte: UInt8 = self.sleepTimer == 0 ? 0xFF : UInt8(self.sleepTimer)
            let lowBatByte: UInt8 = UInt8(clamping: self.lowBatteryWarning)
            let packet: [UInt8] = [self.reportId, 0x51, 0x37, 0x00, 0x00, powerOffByte, 0x00, lowBatByte]
            _ = self.session.writeForResponse(packet: packet)
        }
    }

    // MARK: - DPI

    public func readDpi() {
        // Read active DPI profile
        if let response = session.writeForResponse(packet: [reportId, 0x12, 0x04, 0x02]), response.count >= 6 {
            let stage = Int(response[5])
            DispatchQueue.main.async {
                if stage >= 1 && stage <= 4 {
                    self.activeDpiStage = stage
                }
            }
        }

        // Read DPI stage values
        if let response = session.writeForResponse(packet: [reportId, 0x12, 0x04, 0x01]), response.count >= 13 {
            var newStages: [Int] = []
            for i in 0..<4 {
                let offset = 5 + (i * 2)
                if offset + 1 < response.count {
                    let encoded = Int(response[offset]) | (Int(response[offset + 1]) << 8)
                    newStages.append(encoded * 50)
                }
            }
            if newStages.count == 4 {
                DispatchQueue.main.async {
                    self.dpiStages = newStages
                }
            }
        }
    }

    public func applyActiveDpiStage(_ stage: Int) {
        activeDpiStage = stage
        workQueue.async {
            let packet: [UInt8] = [self.reportId, 0x51, 0x31, 0x09, 0x00, UInt8(stage)]
            _ = self.session.writeForResponse(packet: packet)
        }
    }

    public func applyDpiValues() {
        workQueue.async {
            for (idx, dpi) in self.dpiStages.enumerated() {
                let encoded = UInt16(dpi / 50)
                let lo = UInt8(encoded & 0xFF)
                let hi = UInt8((encoded >> 8) & 0xFF)
                let color = self.dpiColors[idx]
                let (r, g, b) = self.colorToRGB(color)

                let packet: [UInt8] = [self.reportId, 0x51, 0x31, UInt8(idx), 0x00, lo, hi, r, g, b]
                _ = self.session.writeForResponse(packet: packet)
            }
        }
    }

    // MARK: - Performance

    public func readPerformance() {
        if let response = session.writeForResponse(packet: [reportId, 0x12, 0x04, 0x00]), response.count >= 8 {
            let pr = MousePollingRate.fromPacket(value: response[5])
            let debounceVal = Int(response[6])
            let snapping = response[7] == 1

            DispatchQueue.main.async {
                self.pollingRate = pr
                self.debounceTime = debounceVal * 4
                self.angleSnapping = snapping
            }
        }

        if let response = session.writeForResponse(packet: [reportId, 0x12, 0x06]), response.count >= 6 {
            let lod = Int(response[5])
            DispatchQueue.main.async {
                self.liftOffDistance = lod
            }
        }
    }

    public func applyPerformance() {
        workQueue.async {
            // Polling Rate
            _ = self.session.writeForResponse(packet: [self.reportId, 0x51, 0x31, 0x04, 0x00, self.pollingRate.packetValue])

            // Angle Snapping
            _ = self.session.writeForResponse(packet: [self.reportId, 0x51, 0x31, 0x06, 0x00, self.angleSnapping ? 0x01 : 0x00])

            // Debounce Time
            let debounceByte = UInt8(clamping: self.debounceTime / 4)
            _ = self.session.writeForResponse(packet: [self.reportId, 0x51, 0x31, 0x05, 0x00, debounceByte])

            // Lift-Off Distance
            _ = self.session.writeForResponse(packet: [self.reportId, 0x51, 0x35, 0xFF, 0x00, 0xFF, UInt8(self.liftOffDistance)])
        }
    }

    // MARK: - Lighting

    public func readLighting() {
        guard let response = session.writeForResponse(packet: [reportId, 0x12, 0x03, 0x03]), response.count >= 12 else {
            return
        }
        let modeByte = response[5]
        let brightness = Int(response[6])
        let r = Double(response[9]) / 255.0
        let g = Double(response[10]) / 255.0
        let b = Double(response[11]) / 255.0

        DispatchQueue.main.async {
            if let mode = MouseLightingMode(rawValue: modeByte) {
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
            let speed: UInt8 = 0x07 // Medium

            // Set all zones (0x03)
            let packet: [UInt8] = [self.reportId, 0x51, 0x28, 0x03, 0x00, mode, bright, speed, 0x00, r, g, b]
            _ = self.session.writeForResponse(packet: packet)

            // Commit changes
            _ = self.session.writeForResponse(packet: [self.reportId, 0x50, 0x55])
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
