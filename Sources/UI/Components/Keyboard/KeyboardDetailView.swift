import SwiftUI
import AppKit

struct KeyboardDetailView: View {
    @ObservedObject var keyboard: AsusKeyboard
    @State private var selectedTab: Int = 0

    private let presetColors: [(name: String, color: Color)] = [
        ("Red", Color(red: 1.0, green: 0.0, blue: 0.0)),
        ("Orange", Color(red: 1.0, green: 0.45, blue: 0.0)),
        ("Yellow", Color(red: 1.0, green: 0.9, blue: 0.0)),
        ("Green", Color(red: 0.0, green: 1.0, blue: 0.0)),
        ("Cyan", Color(red: 0.0, green: 0.9, blue: 1.0)),
        ("Blue", Color(red: 0.0, green: 0.35, blue: 1.0)),
        ("Purple", Color(red: 0.65, green: 0.0, blue: 1.0)),
        ("White", Color(red: 1.0, green: 1.0, blue: 1.0))
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Lighting").tag(0)
                if keyboard.metadata.hasOled {
                    Text("OLED Display").tag(1)
                }
                if keyboard.metadata.hasBattery {
                    Text("Power").tag(2)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    switch selectedTab {
                    case 0:
                        lightingSection
                    case 1:
                        oledSection
                    case 2:
                        powerSection
                    default:
                        EmptyView()
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 300)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Lighting Section
    private var lightingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Aura Effect")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Picker("", selection: $keyboard.lightingMode) {
                    ForEach(KeyboardLightingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: keyboard.lightingMode) { _ in
                    keyboard.applyLighting()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            // Brightness Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Brightness")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(keyboard.lightingBrightness)%")
                        .font(.system(size: 11, design: .monospaced))
                }
                Slider(
                    value: Binding(
                        get: { Double(keyboard.lightingBrightness) },
                        set: { keyboard.lightingBrightness = Int($0) }
                    ),
                    in: 0...100,
                    step: 5,
                    onEditingChanged: { editing in
                        if !editing { keyboard.applyLighting() }
                    }
                )
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            // Animation Speed
            HStack {
                Text("Effect Speed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Picker("", selection: $keyboard.lightingSpeed) {
                    ForEach(KeyboardSpeed.allCases) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                .onChange(of: keyboard.lightingSpeed) { _ in
                    keyboard.applyLighting()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            // Color Presets
            if keyboard.lightingMode == .static || keyboard.lightingMode == .breathing || keyboard.lightingMode == .reactive {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(presetColors, id: \.name) { preset in
                            Button {
                                keyboard.lightingColor = preset.color
                                keyboard.applyLighting()
                            } label: {
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: keyboard.lightingColor == preset.color ? 2 : 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }
        }
    }

    // MARK: - OLED Section
    private var oledSection: some View {
        VStack(spacing: 12) {
            HStack {
                Toggle("Enable OLED Display", isOn: $keyboard.oledEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: keyboard.oledEnabled) { _ in
                        keyboard.applyOledSettings()
                    }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            if keyboard.oledEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("OLED Brightness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(keyboard.oledBrightness)%")
                            .font(.system(size: 11, design: .monospaced))
                    }
                    Slider(
                        value: Binding(
                            get: { Double(keyboard.oledBrightness) },
                            set: { keyboard.oledBrightness = Int($0) }
                        ),
                        in: 10...100,
                        step: 10,
                        onEditingChanged: { editing in
                            if !editing { keyboard.applyOledSettings() }
                        }
                    )
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

                HStack {
                    Text("Animation Preset")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Picker("", selection: $keyboard.oledAnimation) {
                        Text("ROG Logo").tag(0)
                        Text("Cyber City").tag(1)
                        Text("Pixel Samurai").tag(2)
                        Text("Matrix Stream").tag(3)
                        Text("Equalizer Waves").tag(4)
                        Text("System Info").tag(5)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                    .onChange(of: keyboard.oledAnimation) { _ in
                        keyboard.applyOledSettings()
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Power Section
    private var powerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Sleep Timer")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Picker("", selection: $keyboard.sleepTimer) {
                    Text("1 Minute").tag(1)
                    Text("2 Minutes").tag(2)
                    Text("3 Minutes").tag(3)
                    Text("5 Minutes").tag(5)
                    Text("10 Minutes").tag(10)
                    Text("Never").tag(0)
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: keyboard.sleepTimer) { _ in
                    keyboard.applyEnergySettings()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }
}
