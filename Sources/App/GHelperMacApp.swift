import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
    }

    @objc func colorChanged(_ sender: NSColorPanel) {
        guard let headset = PeripheralManager.shared.selectedHeadset else { return }
        let c = sender.color.usingColorSpace(.sRGB) ?? sender.color
        headset.lightingColor = Color(c)
        headset.applyLighting()
    }
}

@main
struct GHelperMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = PeripheralManager.shared

    var body: some Scene {
        MenuBarExtra {
            HeadsetDetailView(manager: manager)
        } label: {
            Image(nsImage: getMenuBarIcon())
        }
        .menuBarExtraStyle(.window)
    }

    private func getMenuBarIcon() -> NSImage {
        // Try loading bundled tray icon first
        if let bundlePath = Bundle.main.path(forResource: "tray_icon", ofType: "png", inDirectory: nil) ??
            Bundle.main.path(forResource: "tray_icon", ofType: "png", inDirectory: "Resources"),
           let img = NSImage(contentsOfFile: bundlePath) {
            img.isTemplate = true
            return img
        }

        // Crisp vector fallback of G in a circle
        let size: CGFloat = 18
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()

        let ctx = NSGraphicsContext.current!.cgContext
        ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

        let inset: CGFloat = 1.2
        let circleRect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillEllipse(in: circleRect)

        ctx.setBlendMode(.clear)
        let font = NSFont.systemFont(ofSize: 11, weight: .bold)
        let str = NSAttributedString(string: "G", attributes: [
            .font: font,
            .foregroundColor: NSColor.black
        ])
        let strSize = str.size()
        let strRect = CGRect(
            x: (size - strSize.width) / 2 + 0.4,
            y: (size - strSize.height) / 2 + 0.2,
            width: strSize.width,
            height: strSize.height
        )
        str.draw(in: strRect)

        img.unlockFocus()
        img.isTemplate = true
        return img
    }
}
