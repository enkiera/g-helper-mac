import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.ghelper.mac", category: "AsusHeadset")

open class AsusHeadset: ObservableObject, AsusPeripheral, @unchecked Sendable {
    public let id: String
    public let session: HIDDeviceSession
    public let reportId: UInt8 = 0xCC
    public let peripheralType: PeripheralType = .headset

    open var displayName: String { "ASUS ROG Headset" }

    // MARK: - Published State
    @Published public var isReady: Bool = false
    @Published public var battery: Int = 0
    @Published public var isCharging: Bool = false
    @Published public var sleepTimer: SleepTimerOption = .min5
    @Published public var lowBatteryWarning: Int = 20

    // Lighting
    @Published public var lightingMode: HeadsetLightingMode = .static
    @Published public var lightingBrightness: Int = 100
    @Published public var lightingColor: Color = .red

    // Audio & EQ
    @Published public var equalizerEnabled: Bool = false
    @Published public var equalizerGains: [Int] = [50, 50, 50, 50, 50, 50, 50, 50, 50, 50]
    @Published public var selectedPreset: String = "Default"
    @Published public var sidetoneEnabled: Bool = false
    @Published public var sidetoneLevel: Int = 10
    @Published public var noiseReductionEnabled: Bool = false
    @Published public var noiseReductionLevel: NoiseReductionLevel = .low
    @Published public var voicePrompt: VoicePromptOption = .english

    private let workQueue = DispatchQueue(label: "com.ghelper.mac.headset.queue", qos: .userInitiated)

    public init(session: HIDDeviceSession, id: String = UUID().uuidString) {
        self.session = session
        self.id = id
    }

    // MARK: - Telemetry & Synchronization

    public func synchronizeDevice() {
        workQueue.async {
            var batteryInfo = self.readBattery()
            if batteryInfo == nil {
                Thread.sleep(forTimeInterval: 0.3)
                batteryInfo = self.readBattery()
            }
            guard let batteryInfo = batteryInfo else {
                DispatchQueue.main.async {
                    self.isReady = false
                }
                return
            }

            let lighting = self.readLighting()
            let eq = self.readEqualizer()
            let sidetone = self.readSidetone()
            let noise = self.readNoiseReduction()
            let prompt = self.readVoicePrompt()

            DispatchQueue.main.async {
                self.isReady = true
                self.battery = batteryInfo.battery
                self.isCharging = batteryInfo.isCharging
                self.sleepTimer = SleepTimerOption(rawValue: batteryInfo.sleepTimer) ?? .min5
                self.lowBatteryWarning = batteryInfo.lowBatteryWarning

                if let lighting = lighting {
                    self.lightingMode = lighting.mode
                    self.lightingBrightness = lighting.brightness
                    self.lightingColor = lighting.color.swiftUIColor
                }

                if let eq = eq {
                    self.equalizerEnabled = eq.enabled
                    self.equalizerGains = eq.gains.map { Int($0) }
                }

                if let sidetone = sidetone {
                    self.sidetoneEnabled = sidetone.enabled
                    self.sidetoneLevel = sidetone.level
                }

                if let noise = noise {
                    self.noiseReductionEnabled = noise.enabled
                    self.noiseReductionLevel = NoiseReductionLevel(rawValue: noise.level) ?? .low
                }

                if let prompt = prompt {
                    self.voicePrompt = VoicePromptOption(rawValue: prompt) ?? .english
                }

                logger.info("Synchronized \(self.displayName): \(self.battery)% battery")
            }
        }
    }

    public func pollBattery() {
        workQueue.async {
            if let info = self.readBattery() {
                DispatchQueue.main.async {
                    self.isReady = true
                    self.battery = info.battery
                    self.isCharging = info.isCharging
                    self.sleepTimer = SleepTimerOption(rawValue: info.sleepTimer) ?? self.sleepTimer
                    self.lowBatteryWarning = info.lowBatteryWarning
                }
            } else {
                DispatchQueue.main.async {
                    self.isReady = false
                }
            }
        }
    }

    // MARK: - Actions

    public func applyLighting() {
        let mode = lightingMode
        let brightness = lightingBrightness
        let rgb = RGBColor(color: lightingColor)

        workQueue.async {
            self.writeLighting(mode: mode, brightness: brightness, color: rgb)
        }
    }

    public func applyEqualizer() {
        let enabled = equalizerEnabled
        let gains = equalizerGains.map { UInt8(clamping: $0) }

        workQueue.async {
            self.writeEqualizer(enabled: enabled, gains: gains)
        }
    }

    public func selectPreset(_ preset: EqualizerPreset) {
        selectedPreset = preset.name
        equalizerGains = preset.gains.map { Int($0) }
        applyEqualizer()
    }

    public func setEqualizerBand(index: Int, gain: Int) {
        guard index >= 0 && index < equalizerGains.count else { return }
        equalizerGains[index] = gain
        selectedPreset = "Custom"
        applyEqualizer()
    }

    public func applySidetone() {
        let enabled = sidetoneEnabled
        let level = sidetoneLevel

        workQueue.async {
            self.writeSidetone(enabled: enabled, level: level)
        }
    }

    public func applyNoiseReduction() {
        let enabled = noiseReductionEnabled
        let level = noiseReductionLevel.rawValue

        workQueue.async {
            self.writeNoiseReduction(enabled: enabled, level: level)
        }
    }

    public func applyVoicePrompt() {
        let value = voicePrompt.rawValue

        workQueue.async {
            self.writeVoicePrompt(value: value)
        }
    }

    public func applyEnergySettings() {
        let sleep = sleepTimer.rawValue
        let warn = lowBatteryWarning

        workQueue.async {
            self.writeEnergySettings(sleepTimer: sleep, lowBatteryWarning: warn)
        }
    }

    public func resetToDefaults() {
        workQueue.async {
            self.session.writeFireAndForget(packet: [self.reportId, 0x50, 0x40])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.synchronizeDevice()
            }
        }
    }

    // MARK: - Low-Level Packet Methods

    public func readBattery() -> (battery: Int, isCharging: Bool, sleepTimer: Int, lowBatteryWarning: Int)? {
        guard let response = session.writeForResponse(packet: [reportId, 0x12, 0x07]),
              response.count >= 9,
              response[6] <= 100 else {
            return nil
        }

        let sleepTimer = Int(response[5])
        let battery = Int(response[6])
        let lowBatteryWarning = Int(response[7])

        var isCharging = false
        if let chargeResp = session.writeForResponse(packet: [reportId, 0x12, 0x08]), chargeResp.count >= 6 {
            isCharging = chargeResp[5] == 1
        }

        return (battery, isCharging, sleepTimer, lowBatteryWarning)
    }

    public func writeEnergySettings(sleepTimer: Int, lowBatteryWarning: Int, prompt: Bool = true) {
        let packet: [UInt8] = [
            reportId, 0x51, 0x37, 0x00, 0x00,
            UInt8(clamping: sleepTimer),
            UInt8(clamping: lowBatteryWarning),
            prompt ? 1 : 0
        ]
        _ = session.writeForResponse(packet: packet)
    }

    public func readLighting() -> (mode: HeadsetLightingMode, brightness: Int, color: RGBColor)? {
        let status = session.writeForResponse(packet: [reportId, 0x12, 0x13])
        let config = session.writeForResponse(packet: [reportId, 0x12, 0x03])

        guard let config = config, config.count >= 10 else { return nil }

        let isOff = (status != nil && status!.count >= 6 && status![5] == 0)
        let modeRaw = config[5]
        let mode: HeadsetLightingMode
        if isOff {
            mode = .off
        } else {
            mode = HeadsetLightingMode(rawValue: modeRaw) ?? .static
        }

        let brightness = Int(min(config[6], 100))
        let color = RGBColor(red: config[7], green: config[8], blue: config[9])

        return (mode, brightness, color)
    }

    public func writeLighting(mode: HeadsetLightingMode, brightness: Int, color: RGBColor) {
        if mode == .off {
            _ = session.writeForResponse(packet: [reportId, 0x51, 0x10, 0x00, 0x00, 0x00])
            _ = session.writeForResponse(packet: [reportId, 0x50, 0x55])
        } else {
            _ = session.writeForResponse(packet: [reportId, 0x51, 0x10, 0x00, 0x00, 0x01])

            let packet: [UInt8] = [
                reportId, 0x51, 0x28, 0x00, 0x00,
                mode.rawValue,
                UInt8(clamping: brightness),
                color.red, color.green, color.blue
            ]
            _ = session.writeForResponse(packet: packet)
            _ = session.writeForResponse(packet: [reportId, 0x50, 0x55])
        }
    }

    public func readEqualizer() -> (enabled: Bool, gains: [UInt8])? {
        guard let response = session.writeForResponse(packet: [reportId, 0x12, 0x21]), response.count >= 16 else {
            return nil
        }
        let enabled = response[5] == 1
        let gains = Array(response[6..<16])
        return (enabled, gains)
    }

    public func writeEqualizer(enabled: Bool, gains: [UInt8]) {
        _ = session.writeForResponse(packet: [reportId, 0x41, 0x03, 0x00, 0x00, enabled ? 1 : 0])

        if enabled && gains.count == 10 {
            Thread.sleep(forTimeInterval: 0.1)
            var allGainsPacket: [UInt8] = [reportId, 0x41, 0x04, 0x00, 0x00]
            allGainsPacket.append(contentsOf: gains)
            _ = session.writeForResponse(packet: allGainsPacket)

            for (index, gain) in gains.enumerated() {
                let bandPacket: [UInt8] = [reportId, 0x41, 0x06, 0x00, 0x00, UInt8(index), gain]
                _ = session.writeForResponse(packet: bandPacket)
            }
        }
    }

    public func readSidetone() -> (enabled: Bool, level: Int)? {
        guard let state = session.writeForResponse(packet: [reportId, 0x12, 0x24]), state.count >= 6,
              let levelResp = session.writeForResponse(packet: [reportId, 0x12, 0x19]), levelResp.count >= 6 else {
            return nil
        }
        let enabled = state[5] == 1
        let level = min(Int(levelResp[5]), 20)
        return (enabled, level)
    }

    public func writeSidetone(enabled: Bool, level: Int) {
        _ = session.writeForResponse(packet: [reportId, 0x41, 0x11, 0x00, 0x00, enabled ? 1 : 0])
        _ = session.writeForResponse(packet: [reportId, 0x61, 0x11, 0x00, 0x00, UInt8(clamping: level)])
    }

    public func readNoiseReduction() -> (enabled: Bool, level: Int)? {
        guard let response = session.writeForResponse(packet: [reportId, 0x41, 0x20]), response.count >= 7 else {
            return nil
        }
        let enabled = response[5] == 1
        let level = min(Int(response[6]), 2)
        return (enabled, level)
    }

    public func writeNoiseReduction(enabled: Bool, level: Int) {
        _ = session.writeForResponse(packet: [reportId, 0x41, 0x02, 0x00, 0x00, enabled ? 1 : 0])
        _ = session.writeForResponse(packet: [reportId, 0x41, 0x10, 0x00, 0x00, UInt8(clamping: level)])
    }

    public func readVoicePrompt() -> Int? {
        guard let response = session.writeForResponse(packet: [reportId, 0x12, 0x28]), response.count >= 6 else {
            return nil
        }
        return Int(response[5])
    }

    public func writeVoicePrompt(value: Int) {
        _ = session.writeForResponse(packet: [reportId, 0x41, 0x0A, 0x00, 0x00, UInt8(clamping: value)])
    }
}
