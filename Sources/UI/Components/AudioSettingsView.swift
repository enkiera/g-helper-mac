import SwiftUI

struct AudioSettingsView: View {
    @ObservedObject var headset: AsusHeadset

    var body: some View {
        VStack(spacing: 12) {
            // Sidetone
            if headset.hasSidetone {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Microphone Sidetone", isOn: $headset.sidetoneEnabled)
                            .toggleStyle(.switch)
                            .onChange(of: headset.sidetoneEnabled) { _ in
                                headset.applySidetone()
                            }
                        Spacer()
                        if headset.sidetoneEnabled {
                            Text("\(headset.sidetoneLevel) / 20")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    if headset.sidetoneEnabled {
                        Slider(
                            value: Binding(
                                get: { Double(headset.sidetoneLevel) },
                                set: { headset.sidetoneLevel = Int($0) }
                            ),
                            in: 0...20,
                            step: 1,
                            onEditingChanged: { editing in
                                if !editing { headset.applySidetone() }
                            }
                        )
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }

            // Noise Reduction
            if headset.hasNoiseReduction {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Noise Reduction", isOn: $headset.noiseReductionEnabled)
                            .toggleStyle(.switch)
                            .onChange(of: headset.noiseReductionEnabled) { _ in
                                headset.applyNoiseReduction()
                            }

                        Spacer()

                        if headset.noiseReductionEnabled {
                            Picker("", selection: $headset.noiseReductionLevel) {
                                ForEach(NoiseReductionLevel.allCases) { level in
                                    Text(level.displayName).tag(level)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 110)
                            .onChange(of: headset.noiseReductionLevel) { _ in
                                headset.applyNoiseReduction()
                            }
                        }
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }

            // Voice Prompt
            if headset.hasVoicePrompt {
                HStack {
                    Text("Voice Prompt")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Picker("", selection: $headset.voicePrompt) {
                        ForEach(VoicePromptOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 130)
                    .onChange(of: headset.voicePrompt) { _ in
                        headset.applyVoicePrompt()
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }
        }
    }
}
