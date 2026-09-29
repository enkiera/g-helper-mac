import Foundation

public struct MouseMetadata: Sendable {
    public let displayName: String
    public let maxDpi: Int
    public let hasBattery: Bool
    public let reportId: UInt8

    public init(displayName: String, maxDpi: Int = 26000, hasBattery: Bool = true, reportId: UInt8 = 0x00) {
        self.displayName = displayName
        self.maxDpi = maxDpi
        self.hasBattery = hasBattery
        self.reportId = reportId
    }
}

public enum MouseRegistry {
    public static let models: [Int: MouseMetadata] = [
        // ROG Harpe Series
        0x1A94: MouseMetadata(displayName: "ROG Harpe Ace Aim Lab", maxDpi: 36000, hasBattery: true),
        0x1A96: MouseMetadata(displayName: "ROG Harpe Ace (Wired)", maxDpi: 36000, hasBattery: false),
        0x1A97: MouseMetadata(displayName: "ROG Harpe Ace Extreme", maxDpi: 42000, hasBattery: true),
        0x1B63: MouseMetadata(displayName: "ROG Harpe Ace Mini", maxDpi: 42000, hasBattery: true),
        0x1C69: MouseMetadata(displayName: "ROG Harpe II Ace", maxDpi: 42000, hasBattery: true),
        0x1C6B: MouseMetadata(displayName: "ROG Harpe II Ace (Wired)", maxDpi: 42000, hasBattery: false),

        // ROG Keris Series
        0x1B16: MouseMetadata(displayName: "ROG Keris II Ace", maxDpi: 42000, hasBattery: true),
        0x1B18: MouseMetadata(displayName: "ROG Keris II Ace (Wired)", maxDpi: 42000, hasBattery: false),
        0x1C0C: MouseMetadata(displayName: "ROG Keris II Origin", maxDpi: 42000, hasBattery: true),
        0x1C0E: MouseMetadata(displayName: "ROG Keris II Origin (Wired)", maxDpi: 42000, hasBattery: false),
        0x1A68: MouseMetadata(displayName: "ROG Keris Wireless Aimpoint", maxDpi: 36000, hasBattery: true),
        0x1A6A: MouseMetadata(displayName: "ROG Keris Aimpoint (Wired)", maxDpi: 36000, hasBattery: false),
        0x1960: MouseMetadata(displayName: "ROG Keris Wireless", maxDpi: 16000, hasBattery: true),
        0x1962: MouseMetadata(displayName: "ROG Keris (Wired)", maxDpi: 16000, hasBattery: false),

        // ROG Gladius Series
        0x1A72: MouseMetadata(displayName: "ROG Gladius III Aimpoint", maxDpi: 36000, hasBattery: true),
        0x1A74: MouseMetadata(displayName: "ROG Gladius III Aimpoint (Wired)", maxDpi: 36000, hasBattery: false),
        0x1B0A: MouseMetadata(displayName: "ROG Gladius III Aimpoint EVA-02", maxDpi: 36000, hasBattery: true),
        0x1B0C: MouseMetadata(displayName: "ROG Gladius III Aimpoint EVA-02 (Wired)", maxDpi: 36000, hasBattery: false),
        0x197F: MouseMetadata(displayName: "ROG Gladius III Wireless", maxDpi: 26000, hasBattery: true),
        0x1981: MouseMetadata(displayName: "ROG Gladius III (Wired)", maxDpi: 26000, hasBattery: false),
        0x18A0: MouseMetadata(displayName: "ROG Gladius II Wireless", maxDpi: 16000, hasBattery: true),
        0x18A2: MouseMetadata(displayName: "ROG Gladius II (Wired)", maxDpi: 16000, hasBattery: false),
        0x1877: MouseMetadata(displayName: "ROG Gladius II Origin", maxDpi: 12000, hasBattery: false),

        // ROG Chakram Series
        0x1A1A: MouseMetadata(displayName: "ROG Chakram X", maxDpi: 36000, hasBattery: true),
        0x1A1C: MouseMetadata(displayName: "ROG Chakram X (Wired)", maxDpi: 36000, hasBattery: false),
        0x18E5: MouseMetadata(displayName: "ROG Chakram", maxDpi: 16000, hasBattery: true),
        0x18E7: MouseMetadata(displayName: "ROG Chakram (Wired)", maxDpi: 16000, hasBattery: false),
        0x1958: MouseMetadata(displayName: "ROG Chakram Core", maxDpi: 16000, hasBattery: false),

        // ROG Spatha Series
        0x1979: MouseMetadata(displayName: "ROG Spatha X", maxDpi: 19000, hasBattery: true),
        0x197B: MouseMetadata(displayName: "ROG Spatha X (Wired)", maxDpi: 19000, hasBattery: false),

        // ROG Pugio Series
        0x1908: MouseMetadata(displayName: "ROG Pugio II", maxDpi: 16000, hasBattery: true),
        0x190A: MouseMetadata(displayName: "ROG Pugio II (Wired)", maxDpi: 16000, hasBattery: false),
        0x1846: MouseMetadata(displayName: "ROG Pugio", maxDpi: 7200, hasBattery: false),

        // ROG Strix Impact Series
        0x1ACE: MouseMetadata(displayName: "ROG Strix Impact III Wireless", maxDpi: 36000, hasBattery: true),
        0x1A88: MouseMetadata(displayName: "ROG Strix Impact III", maxDpi: 12000, hasBattery: false),
        0x1949: MouseMetadata(displayName: "ROG Strix Impact II Wireless", maxDpi: 16000, hasBattery: true),
        0x194B: MouseMetadata(displayName: "ROG Strix Impact II Wireless (Wired)", maxDpi: 16000, hasBattery: false),
        0x18E1: MouseMetadata(displayName: "ROG Strix Impact II", maxDpi: 6200, hasBattery: false),
        0x19D2: MouseMetadata(displayName: "ROG Strix Impact II Electro Punk", maxDpi: 6200, hasBattery: false),
        0x1956: MouseMetadata(displayName: "ROG Strix Impact II Moonlight White", maxDpi: 6200, hasBattery: false),
        0x1847: MouseMetadata(displayName: "ROG Strix Impact", maxDpi: 5000, hasBattery: false),

        // ROG Carry & Evolve
        0x18B4: MouseMetadata(displayName: "ROG Strix Carry", maxDpi: 7200, hasBattery: true),
        0x185B: MouseMetadata(displayName: "ROG Strix Evolve", maxDpi: 7200, hasBattery: false),

        // ASUS TUF Mice
        0x1A03: MouseMetadata(displayName: "TUF Gaming M4 Air", maxDpi: 16000, hasBattery: false),
        0x19F4: MouseMetadata(displayName: "TUF Gaming M4 Wireless", maxDpi: 12000, hasBattery: true),
        0x1910: MouseMetadata(displayName: "TUF Gaming M3", maxDpi: 7000, hasBattery: false),
        0x1898: MouseMetadata(displayName: "TUF Gaming M5", maxDpi: 6200, hasBattery: false),

        // ProArt & Balteus
        0x1A24: MouseMetadata(displayName: "ProArt Mouse MD200", maxDpi: 4200, hasBattery: true),
        0x1891: MouseMetadata(displayName: "ROG Balteus Mousepad", maxDpi: 0, hasBattery: false)
    ]

    public static func isMouse(productId: Int) -> Bool {
        return models[productId] != nil
    }

    public static func getMetadata(productId: Int) -> MouseMetadata? {
        return models[productId]
    }
}
