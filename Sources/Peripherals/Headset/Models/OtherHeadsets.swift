import Foundation

public final class ROGPelta: AsusHeadset, @unchecked Sendable {
    public static let productID = 0x1B84
    public override var displayName: String { "ROG Pelta" }
}

public final class ROGCetraSpeedNova: AsusHeadset, @unchecked Sendable {
    public static let productID = 0x1AD3
    public override var displayName: String { "ROG Cetra SpeedNova" }
}

public final class ROGClavis: AsusHeadset, @unchecked Sendable {
    public static let productID = 0x1928
    public override var displayName: String { "ROG Clavis" }
}

public final class ROGCetraRGB: AsusHeadset, @unchecked Sendable {
    public static let productID = 0x18F6
    public static let productID2 = 0x18DE
    public override var displayName: String { "ROG Cetra RGB" }
}

public final class ROGStrixGo24: AsusHeadset, @unchecked Sendable {
    public static let productID = 0x18D6

    public override var displayName: String { "ROG Strix Go 2.4" }
    public override var reportId: UInt8 { 0xFF }

    public override var hasEqualizer: Bool { false }
    public override var hasLighting: Bool { false }
    public override var hasSidetone: Bool { false }
    public override var hasNoiseReduction: Bool { true }
    public override var hasVoicePrompt: Bool { false }
    public override var hasLowBatteryWarning: Bool { false }
    public override var hasReset: Bool { false }

    public override func readBattery() -> (battery: Int, isCharging: Bool, sleepTimer: Int, lowBatteryWarning: Int)? {
        guard let response = session.writeForResponse(packet: [reportId, 0x08, 0x00, 0xFD, 0x04, 0x12, 0xF1, 0x03, 0x52, 0x01]),
              response.count >= 23,
              response[1] == 0x1B else {
            return nil
        }

        let millivolts = (Int(response[12]) << 8) | Int(response[11])
        let battery: Int
        if millivolts >= 4100 { battery = 100 }
        else if millivolts >= 3800 { battery = 75 }
        else if millivolts >= 3700 { battery = 50 }
        else if millivolts >= 3500 { battery = 25 }
        else { battery = 10 }

        let isCharging = response[9] == 0x0A
        let sleepTimer = ((Int(response[22]) << 8) | Int(response[21])) / 60

        return (battery, isCharging, sleepTimer, 20)
    }

    public override func writeEnergySettings(sleepTimer: Int, lowBatteryWarning: Int, prompt: Bool = true) {
        let seconds = sleepTimer * 60
        let packet: [UInt8] = [
            reportId, 0x0A, 0x00, 0xFF, 0x04, 0x12, 0xF1, 0x05, 0x52, 0x0B,
            UInt8(seconds & 0xFF),
            UInt8((seconds >> 8) & 0xFF)
        ]
        _ = session.writeForResponse(packet: packet)
    }

    public override func writeNoiseReduction(enabled: Bool, level: Int) {
        let packet: [UInt8] = [
            reportId, 0x08, 0x00, 0xFF, 0x04, 0x12, 0xF1, 0x03, 0x52,
            enabled ? 0x0D : 0x0C
        ]
        _ = session.writeForResponse(packet: packet)
    }
}
