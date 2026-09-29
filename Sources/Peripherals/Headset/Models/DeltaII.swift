import Foundation

public final class ROGDeltaII: AsusHeadset, @unchecked Sendable {
    public static let productID = 0x1AFA
    public static let productIDKJP = 0x1D41

    public override var displayName: String {
        return "ROG Delta II"
    }

    public override init(session: HIDDeviceSession, id: String = UUID().uuidString) {
        super.init(session: session, id: id)
    }
}
