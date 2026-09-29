import Foundation

public struct KeyboardMetadata: Sendable {
    public let displayName: String
    public let hasBattery: Bool
    public let hasOled: Bool
    public let reportId: UInt8

    public init(displayName: String, hasBattery: Bool = false, hasOled: Bool = false, reportId: UInt8 = 0x00) {
        self.displayName = displayName
        self.hasBattery = hasBattery
        self.hasOled = hasOled
        self.reportId = reportId
    }
}

public enum KeyboardRegistry {
    public static let models: [Int: KeyboardMetadata] = [
        // ROG Azoth Series
        0x1A83: KeyboardMetadata(displayName: "ROG Azoth", hasBattery: true, hasOled: true),
        0x1C25: KeyboardMetadata(displayName: "ROG Azoth Wireless", hasBattery: true, hasOled: true),
        0x1CEF: KeyboardMetadata(displayName: "ROG Azoth Extreme", hasBattery: true, hasOled: true),
        0x1D02: KeyboardMetadata(displayName: "ROG Azoth Extreme SE", hasBattery: true, hasOled: true),

        // ROG Claymore Series
        0x196B: KeyboardMetadata(displayName: "ROG Claymore II", hasBattery: true, hasOled: false),

        // ROG Falchion Series
        0x193C: KeyboardMetadata(displayName: "ROG Falchion", hasBattery: true, hasOled: false),
        0x1A64: KeyboardMetadata(displayName: "ROG Falchion Wireless", hasBattery: true, hasOled: false),
        0x1B04: KeyboardMetadata(displayName: "ROG Falchion RX Low-Profile", hasBattery: true, hasOled: false),
        0x1B7E: KeyboardMetadata(displayName: "ROG Falchion Ace", hasBattery: false, hasOled: false),

        // ROG Strix Scope II Series
        0x1AAE: KeyboardMetadata(displayName: "ROG Strix Scope II", hasBattery: false, hasOled: false),
        0x1AB3: KeyboardMetadata(displayName: "ROG Strix Scope II RX", hasBattery: false, hasOled: false),
        0x1AB5: KeyboardMetadata(displayName: "ROG Strix Scope II 96 Wireless", hasBattery: true, hasOled: false),
        0x1B78: KeyboardMetadata(displayName: "ROG Strix Scope II 96 RX Wireless", hasBattery: true, hasOled: false),

        // ROG Strix Scope RX Series
        0x1A07: KeyboardMetadata(displayName: "ROG Strix Scope RX TKL Wireless", hasBattery: true, hasOled: false),
        0x1951: KeyboardMetadata(displayName: "ROG Strix Scope RX TKL", hasBattery: false, hasOled: false),
        0x1A05: KeyboardMetadata(displayName: "ROG Strix Scope RX", hasBattery: false, hasOled: false),
        0x1A55: KeyboardMetadata(displayName: "ROG Strix Scope RX EVA Edition", hasBattery: false, hasOled: false),
        0x1B12: KeyboardMetadata(displayName: "ROG Strix Scope RX EVA-02", hasBattery: false, hasOled: false),

        // ROG Strix Flare Series
        0x1875: KeyboardMetadata(displayName: "ROG Strix Flare", hasBattery: false, hasOled: false),
        0x18AF: KeyboardMetadata(displayName: "ROG Strix Flare COD", hasBattery: false, hasOled: false),
        0x18CF: KeyboardMetadata(displayName: "ROG Strix Flare PNK", hasBattery: false, hasOled: false),
        0x19FC: KeyboardMetadata(displayName: "ROG Strix Flare II", hasBattery: false, hasOled: false),
        0x19FE: KeyboardMetadata(displayName: "ROG Strix Flare II Animate", hasBattery: false, hasOled: true),

        // ASUS TUF Keyboards
        0x1945: KeyboardMetadata(displayName: "TUF Gaming K1", hasBattery: false, hasOled: false),
        0x194B: KeyboardMetadata(displayName: "TUF Gaming K3", hasBattery: false, hasOled: false),
        0x1B30: KeyboardMetadata(displayName: "TUF Gaming K3 Gen II", hasBattery: false, hasOled: false)
    ]

    public static func isKeyboard(productId: Int) -> Bool {
        return models[productId] != nil
    }

    public static func getMetadata(productId: Int) -> KeyboardMetadata? {
        return models[productId]
    }
}
