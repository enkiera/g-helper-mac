import SwiftUI
import AppKit

// Native macOS visual effect view that blurs desktop content behind the window
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// Configures the parent NSWindow to have clear backing and seamless shadow
private class WindowConfigView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window = window else { return }
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.invalidateShadow()
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        return WindowConfigView()
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct HeadsetDetailView: View {
    @ObservedObject var manager: PeripheralManager
    @State private var selectedHeadsetTab: Int = 0
    @State private var isRefreshing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Multi-Device Switcher (Shown if multiple ASUS devices connected)
            if manager.allPeripherals.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(manager.allPeripherals, id: \.id) { dev in
                            Button {
                                manager.selectedPeripheralID = dev.id
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: dev.peripheralType.iconName)
                                    Text(dev.displayName)
                                        .font(.subheadline)
                                    if dev.isReady && dev.battery > 0 {
                                        Text("\(dev.battery)%")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(dev.battery < 20 ? .red : .secondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(manager.selectedPeripheralID == dev.id ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(manager.selectedPeripheralID == dev.id ? Color.accentColor.opacity(0.8) : Color.white.opacity(0.12), lineWidth: 1)
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                Divider()
                    .opacity(0.3)
            }

            if let peripheral = manager.selectedPeripheral {
                // Device Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(peripheral.isReady ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: peripheral.peripheralType.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(peripheral.isReady ? .accentColor : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(peripheral.displayName)
                            .font(.headline)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(peripheral.isReady ? Color.green : Color.orange)
                                .frame(width: 7, height: 7)

                            Text(peripheral.isReady ? "Connected" : "Sleeping / Standby")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if peripheral.isReady && peripheral.battery > 0 {
                        // Battery indicator
                        HStack(spacing: 6) {
                            Image(systemName: peripheral.isCharging ? "battery.100.bolt" : batteryIcon(for: peripheral.battery))
                                .foregroundColor(batteryColor(for: peripheral.battery, isCharging: peripheral.isCharging))

                            Text("\(peripheral.battery)%")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                    }

                    Button {
                        isRefreshing = true
                        peripheral.synchronizeDevice()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isRefreshing = false
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 26, height: 26)
                    .background(.thinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                }
                .padding(.horizontal, 16)
                .padding(.top, manager.allPeripherals.count > 1 ? 10 : 16)
                .padding(.bottom, 12)

                Divider()
                    .opacity(0.3)

                // Render device-specific UI controls
                if let headset = peripheral as? AsusHeadset {
                    if headset.isReady {
                        headsetControls(headset: headset)
                    } else {
                        deviceSleepingView(title: "Headset is Asleep or Switched Off", icon: "headphones.circle")
                    }
                } else if let mouse = peripheral as? AsusMouse {
                    if mouse.isReady {
                        MouseDetailView(mouse: mouse)
                    } else {
                        deviceSleepingView(title: "Mouse is Sleeping or Switched Off", icon: "computermouse.fill")
                    }
                } else if let keyboard = peripheral as? AsusKeyboard {
                    if keyboard.isReady {
                        KeyboardDetailView(keyboard: keyboard)
                    } else {
                        deviceSleepingView(title: "Keyboard is Sleeping or Switched Off", icon: "keyboard.fill")
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No ASUS Peripherals Connected\nPlug in a 2.4GHz Dongle or USB Device")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 350)
                .padding(16)
            }

            Divider()
                .opacity(0.3)

            // Footer
            HStack {
                Text("GHelper Mac")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 390)
        .background(
            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
        )
        .background(WindowConfigurator())
    }

    // MARK: - Headset Controls Subview
    @ViewBuilder
    private func headsetControls(headset: AsusHeadset) -> some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedHeadsetTab) {
                Text("Equalizer").tag(0)
                Text("Lighting").tag(1)
                Text("Audio").tag(2)
                Text("Power").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch selectedHeadsetTab {
                    case 0:
                        EqualizerView(headset: headset)
                    case 1:
                        LightingView(headset: headset)
                    case 2:
                        AudioSettingsView(headset: headset)
                    case 3:
                        PowerSettingsView(headset: headset)
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

    @ViewBuilder
    private func deviceSleepingView(title: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 350)
        .padding(16)
    }

    private func batteryIcon(for percentage: Int) -> String {
        switch percentage {
        case 0..<20: return "battery.0"
        case 20..<50: return "battery.25"
        case 50..<80: return "battery.75"
        default: return "battery.100"
        }
    }

    private func batteryColor(for percentage: Int, isCharging: Bool) -> Color {
        if isCharging { return .green }
        switch percentage {
        case 0..<20: return .red
        case 20..<40: return .orange
        default: return .primary
        }
    }
}
