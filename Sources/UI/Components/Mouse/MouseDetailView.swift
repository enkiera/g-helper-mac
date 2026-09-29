import SwiftUI
import AppKit

struct MouseDetailView: View {
    @ObservedObject var mouse: AsusMouse
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
                Text("DPI").tag(0)
                Text("Performance").tag(1)
                Text("Lighting").tag(2)
                if mouse.metadata.hasBattery {
                    Text("Power").tag(3)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    switch selectedTab {
                    case 0:
                        dpiSection
                    case 1:
                        performanceSection
                    case 2:
                        lightingSection
                    case 3:
                        powerSection
                    default:
                        EmptyView()
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(height: 350)
    }

    // MARK: - DPI Section
    private var dpiSection: some View {
        VStack(spacing: 10) {
            // Stage Selection Pills
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { stage in
                    Button {
                        mouse.applyActiveDpiStage(stage)
                    } label: {
                        VStack(spacing: 3) {
                            Text("Stage \(stage)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(mouse.dpiStages[stage - 1])")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(mouse.activeDpiStage == stage ? .accentColor : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(mouse.activeDpiStage == stage ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(mouse.activeDpiStage == stage ? Color.accentColor : Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Sliders for each stage
            ForEach(0..<4, id: \.self) { idx in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(mouse.dpiColors[idx])
                            .frame(width: 8, height: 8)
                        Text("Stage \(idx + 1) DPI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(mouse.dpiStages[idx]) DPI")
                            .font(.system(size: 11, design: .monospaced))
                    }

                    Slider(
                        value: Binding(
                            get: { Double(mouse.dpiStages[idx]) },
                            set: { mouse.dpiStages[idx] = Int($0) }
                        ),
                        in: 100...Double(mouse.metadata.maxDpi),
                        step: 50,
                        onEditingChanged: { editing in
                            if !editing { mouse.applyDpiValues() }
                        }
                    )
                }
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(spacing: 12) {
            // Polling Rate
            HStack {
                Text("Polling Rate")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Picker("", selection: $mouse.pollingRate) {
                    ForEach(MousePollingRate.allCases) { rate in
                        Text(rate.displayName).tag(rate)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                .onChange(of: mouse.pollingRate) { _ in
                    mouse.applyPerformance()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            // Angle Snapping
            HStack {
                Toggle("Angle Snapping", isOn: $mouse.angleSnapping)
                    .toggleStyle(.switch)
                    .onChange(of: mouse.angleSnapping) { _ in
                        mouse.applyPerformance()
                    }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            // Lift-Off Distance
            HStack {
                Text("Lift-Off Distance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Picker("", selection: $mouse.liftOffDistance) {
                    Text("Low (1mm)").tag(0)
                    Text("High (2mm)").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .onChange(of: mouse.liftOffDistance) { _ in
                    mouse.applyPerformance()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            // Debounce Time
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Button Debounce Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(mouse.debounceTime) ms")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { Double(mouse.debounceTime) },
                        set: { mouse.debounceTime = Int($0) }
                    ),
                    in: 0...32,
                    step: 4,
                    onEditingChanged: { editing in
                        if !editing { mouse.applyPerformance() }
                    }
                )
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }

    // MARK: - Lighting Section
    private var lightingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Lighting Effect")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Picker("", selection: $mouse.lightingMode) {
                    ForEach(MouseLightingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: mouse.lightingMode) { _ in
                    mouse.applyLighting()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            if mouse.lightingMode != .off {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Brightness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(mouse.lightingBrightness)%")
                            .font(.system(size: 11, design: .monospaced))
                    }
                    Slider(
                        value: Binding(
                            get: { Double(mouse.lightingBrightness) },
                            set: { mouse.lightingBrightness = Int($0) }
                        ),
                        in: 0...100,
                        step: 5,
                        onEditingChanged: { editing in
                            if !editing { mouse.applyLighting() }
                        }
                    )
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

                // Color Swatches
                if mouse.lightingMode == .static || mouse.lightingMode == .breathing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(presetColors, id: \.name) { preset in
                                Button {
                                    mouse.lightingColor = preset.color
                                    mouse.applyLighting()
                                } label: {
                                    Circle()
                                        .fill(preset.color)
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: mouse.lightingColor == preset.color ? 2 : 0.5)
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
    }

    // MARK: - Power Section
    private var powerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Sleep Timer")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Picker("", selection: $mouse.sleepTimer) {
                    Text("1 Minute").tag(1)
                    Text("2 Minutes").tag(2)
                    Text("3 Minutes").tag(3)
                    Text("5 Minutes").tag(5)
                    Text("10 Minutes").tag(10)
                    Text("Never").tag(0)
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: mouse.sleepTimer) { _ in
                    mouse.applyEnergySettings()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Low Battery Warning")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(mouse.lowBatteryWarning)%")
                        .font(.system(size: 11, design: .monospaced))
                }
                Slider(
                    value: Binding(
                        get: { Double(mouse.lowBatteryWarning) },
                        set: { mouse.lowBatteryWarning = Int($0) }
                    ),
                    in: 10...50,
                    step: 5,
                    onEditingChanged: { editing in
                        if !editing { mouse.applyEnergySettings() }
                    }
                )
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }
}
