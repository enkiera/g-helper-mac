import Foundation

public enum PeripheralType: String, CaseIterable, Identifiable {
    case headset = "Headset"
    case mouse = "Mouse"
    case keyboard = "Keyboard"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .headset: return "headphones"
        case .mouse: return "computermouse"
        case .keyboard: return "keyboard"
        }
    }
}

public protocol AsusPeripheral: AnyObject, Identifiable {
    var id: String { get }
    var displayName: String { get }
    var peripheralType: PeripheralType { get }
    var battery: Int { get }
    var isCharging: Bool { get }
    var isReady: Bool { get }

    func synchronizeDevice()
    func pollBattery()
}

extension AsusPeripheral {
    public var iconSymbol: String {
        if displayName.contains("Dock") {
            return "dock.rectangle"
        }
        if displayName.contains("Balteus") || displayName.contains("Mousepad") {
            return "square.inset.filled"
        }
        return peripheralType.iconName
    }
}
