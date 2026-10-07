import SwiftUI

struct PowerSettingsView: View {
    @ObservedObject var headset: AsusHeadset
    @State private var showingResetAlert = false

    var body: some View {
        VStack(spacing: 12) {
            // Auto Power Off / Sleep Timer
            HStack {
                Text("Auto Power Off")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Picker("", selection: $headset.sleepTimer) {
                    ForEach(SleepTimerOption.allCases) { opt in
                        Text(opt.displayName).tag(opt)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: headset.sleepTimer) { _ in
                    headset.applyEnergySettings()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            // Low Battery Warning
            if headset.hasLowBatteryWarning {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Low Battery Warning")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(headset.lowBatteryWarning)%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(headset.lowBatteryWarning) },
                            set: { headset.lowBatteryWarning = Int($0) }
                        ),
                        in: 10...50,
                        step: 5,
                        onEditingChanged: { editing in
                            if !editing { headset.applyEnergySettings() }
                        }
                    )
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }

            // Reset Button
            if headset.hasReset {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Headset to Factory Defaults")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .alert("Reset Headset?", isPresented: $showingResetAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        headset.resetToDefaults()
                    }
                } message: {
                    Text("This will restore lighting, equalizer, and power settings on your headset to factory defaults.")
                }
            }
        }
    }
}
