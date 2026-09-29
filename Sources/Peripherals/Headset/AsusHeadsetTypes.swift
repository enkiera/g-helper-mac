import Foundation
import SwiftUI

public enum HeadsetLightingMode: UInt8, CaseIterable, Identifiable, Sendable {
    case off = 0
    case `static` = 1
    case breathing = 2
    case strobing = 3
    case colorCycle = 4
    case rainbow = 5
    case mqaIndicator = 6

    public var id: UInt8 { rawValue }

    public var displayName: String {
        switch self {
        case .off: return "Off"
        case .static: return "Static"
        case .breathing: return "Breathing"
        case .strobing: return "Strobing"
        case .colorCycle: return "Color Cycle"
        case .rainbow: return "Rainbow"
        case .mqaIndicator: return "MQA Indicator"
        }
    }
}

public enum NoiseReductionLevel: Int, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

public enum VoicePromptOption: Int, CaseIterable, Identifiable {
    case promptSound = 0
    case english = 1
    case chinese = 2

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .promptSound: return "Beep Sound"
        case .english: return "English"
        case .chinese: return "Chinese"
        }
    }
}

public enum SleepTimerOption: Int, CaseIterable, Identifiable {
    case min2 = 2
    case min3 = 3
    case min5 = 5
    case min10 = 10
    case min15 = 15
    case never = 0

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .never: return "Never"
        default: return "\(rawValue) Minutes"
        }
    }
}

public struct EqualizerPreset: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let gains: [UInt8]

    public init(name: String, gains: [UInt8]) {
        self.name = name
        self.gains = gains
    }

    public static let standardPresets: [EqualizerPreset] = [
        EqualizerPreset(name: "Default", gains: [50, 50, 50, 50, 50, 50, 50, 50, 50, 50]),
        EqualizerPreset(name: "Classic", gains: [50, 50, 100, 100, 50, 50, 50, 50, 66, 66]),
        EqualizerPreset(name: "Hip hop", gains: [50, 50, 90, 58, 40, 40, 50, 50, 82, 82]),
        EqualizerPreset(name: "Jazz", gains: [50, 50, 50, 74, 74, 74, 50, 66, 82, 82]),
        EqualizerPreset(name: "Metal", gains: [50, 50, 50, 50, 50, 50, 74, 50, 74, 58]),
        EqualizerPreset(name: "Rock", gains: [50, 50, 66, 74, 40, 40, 50, 50, 82, 82]),
        EqualizerPreset(name: "Techno", gains: [50, 50, 82, 40, 40, 32, 50, 50, 90, 90]),
        EqualizerPreset(name: "Vocal", gains: [50, 50, 66, 58, 50, 50, 50, 50, 32, 8]),
    ]
}

public struct RGBColor: Equatable, Sendable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(color: Color) {
        #if canImport(AppKit)
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.red
        self.red = UInt8(clamping: Int(nsColor.redComponent * 255))
        self.green = UInt8(clamping: Int(nsColor.greenComponent * 255))
        self.blue = UInt8(clamping: Int(nsColor.blueComponent * 255))
        #else
        self.red = 255
        self.green = 0
        self.blue = 0
        #endif
    }

    public var swiftUIColor: Color {
        Color(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }
}
