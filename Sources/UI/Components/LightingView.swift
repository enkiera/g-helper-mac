import SwiftUI
import AppKit

struct LightingView: View {
    @ObservedObject var headset: AsusHeadset

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
        VStack(alignment: .leading, spacing: 12) {
            // Mode Picker
            HStack {
                Text("Aura Lighting Mode")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Picker("", selection: $headset.lightingMode) {
                    ForEach(HeadsetLightingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: headset.lightingMode) { _ in
                    headset.applyLighting()
                }
            }

            if headset.lightingMode != .off {
                Divider()
                    .opacity(0.4)

                // Brightness Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Brightness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(headset.lightingBrightness)%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "sun.min")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(
                            value: Binding(
                                get: { Double(headset.lightingBrightness) },
                                set: { newValue in
                                    headset.lightingBrightness = Int(newValue)
                                }
                            ),
                            in: 0...100,
                            step: 5,
                            onEditingChanged: { isEditing in
                                if !isEditing {
                                    headset.applyLighting()
                                }
                            }
                        )

                        Image(systemName: "sun.max")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Color Selection (for Static, Breathing, Strobing)
                if headset.lightingMode == .static || headset.lightingMode == .breathing || headset.lightingMode == .strobing {
                    Divider()
                        .opacity(0.4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Color Presets")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            // Active color swatch indicator
                            Circle()
                                .fill(headset.lightingColor)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))

                            Button("Custom...") {
                                openNativeColorPanel()
                            }
                            .font(.caption2)
                            .buttonStyle(.borderless)
                        }

                        // Color Preset Swatches
                        HStack(spacing: 8) {
                            ForEach(presetColors, id: \.name) { preset in
                                Button {
                                    headset.lightingColor = preset.color
                                    headset.applyLighting()
                                } label: {
                                    Circle()
                                        .fill(preset.color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: headset.lightingColor == preset.color ? 2 : 0.5)
                                                .opacity(headset.lightingColor == preset.color ? 0.9 : 0.2)
                                        )
                                        .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
    }

    private func openNativeColorPanel() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSColorPanel.shared
        panel.level = .floating
        panel.isContinuous = true
        panel.color = NSColor(headset.lightingColor)

        panel.setTarget(NSApp.delegate)
        panel.setAction(#selector(AppDelegate.colorChanged(_:)))
        panel.orderFront(nil)
    }
}
