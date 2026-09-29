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
