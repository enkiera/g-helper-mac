import SwiftUI

struct VerticalEQSlider: View {
    let gain: Int // 0 to 100 (50 is 0 dB)
    let isEnabled: Bool
    let onGainChanged: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            let normalized = Double(gain) / 100.0
            let thumbY = totalHeight * (1.0 - normalized)

            ZStack {
                // Background groove
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: 4, height: totalHeight)

                // 0 dB center tick mark
                Rectangle()
                    .fill(Color.secondary.opacity(0.45))
                    .frame(width: 14, height: 1.5)
                    .position(x: geo.size.width / 2, y: totalHeight * 0.5)

                // Active level bar from center
                if normalized > 0.5 {
                    let barHeight = (normalized - 0.5) * totalHeight
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isEnabled ? Color.accentColor : Color.secondary)
                        .frame(width: 4, height: barHeight)
                        .position(x: geo.size.width / 2, y: totalHeight * 0.5 - barHeight / 2)
                } else if normalized < 0.5 {
                    let barHeight = (0.5 - normalized) * totalHeight
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isEnabled ? Color.accentColor.opacity(0.6) : Color.secondary)
                        .frame(width: 4, height: barHeight)
                        .position(x: geo.size.width / 2, y: totalHeight * 0.5 + barHeight / 2)
                }

                // Thumb knob
                Circle()
                    .fill(isEnabled ? Color.white : Color(NSColor.disabledControlTextColor))
                    .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                    .frame(width: 14, height: 14)
                    .position(x: geo.size.width / 2, y: thumbY)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        guard isEnabled else { return }
                        let clampedY = max(0, min(totalHeight, drag.location.y))
                        let newNorm = 1.0 - (clampedY / totalHeight)
                        let newGain = Int(round(newNorm * 100.0))
                        onGainChanged(max(0, min(100, newGain)))
                    }
            )
        }
        .frame(width: 26, height: 120)
    }
}

struct EqualizerView: View {
    @ObservedObject var headset: AsusHeadset

    private let frequencies = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Equalizer Enabled", isOn: $headset.equalizerEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: headset.equalizerEnabled) { _ in
                        headset.applyEqualizer()
                    }

                Spacer()

                Menu {
                    ForEach(EqualizerPreset.standardPresets) { preset in
                        Button(preset.name) {
                            headset.selectPreset(preset)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(headset.selectedPreset)
                            .font(.subheadline)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(6)
                }
                .disabled(!headset.equalizerEnabled)
            }

            // 10-Band EQ Sliders
            HStack(spacing: 4) {
                ForEach(0..<10, id: \.self) { index in
                    VStack(spacing: 6) {
                        let db = (headset.equalizerGains[index] - 50) / 4
                        Text(db > 0 ? "+\(db)" : "\(db)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)

                        VerticalEQSlider(
                            gain: headset.equalizerGains[index],
                            isEnabled: headset.equalizerEnabled
                        ) { newGain in
                            headset.setEqualizerBand(index: index, gain: newGain)
                        }

                        Text(frequencies[index])
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
    }
}
