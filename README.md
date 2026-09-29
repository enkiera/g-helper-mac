# GHelper Mac

A lightweight, native macOS menu bar utility for controlling ASUS ROG and TUF gaming peripherals, inspired by [G-Helper](https://github.com/seerge/g-helper).

Built with **Swift, SwiftUI, and Apple IOKit HID** with zero external dependencies and a lean binary footprint (~1 MB).

---

## ✨ Features

- **Liquid Glass Aesthetic:** Designed specifically for modern macOS with native `.behindWindow` frosted glass vibrancy, subtle hairline borders, and fluid animations.
- **Dedicated Menu Bar Icon:** Clean monochrome circular G-Helper icon matching the macOS menu bar style.
- **Multi-Device Support:** Plug in multiple ASUS peripherals simultaneously; the app dynamically adds a top pill-switcher with device-specific icons (🎧, 🖱️, ⌨️) and live battery readouts.
- **Pure User-Space USB HID:** Direct vendor-page (`0xFF00`) communication using native `IOKit.hid`. Requires zero kernel drivers, system extensions, or accessibility permissions.

---

## 🎮 Supported Peripherals & Capabilities

### 🎧 Headsets
- **10-Band Graphic Equalizer:** Frequency adjustment from 32 Hz to 16 kHz with built-in ASUS profiles (*Default, Classic, Rock, Hip Hop, Jazz, Metal, Techno, Vocal*) and real-time hardware sync.
- **Aura RGB Lighting:** Modes (*Static, Breathing, Color Cycle, Off*), brightness control, preset colors, and native macOS color panel support.
- **Audio Tuning:** Microphone Sidetone volume slider, ASUS AI Noise Reduction (*Low, Medium, High*), and Voice Prompts.
- **Power Management:** Auto-sleep timer (1–10m or Never), low battery threshold slider, live charging state, and factory reset.
- *Supported Models:* ROG Delta II, ROG Delta II KJP, ROG Pelta, ROG Cetra SpeedNova, ROG Cetra RGB, ROG Clavis DAC/Amp.

### 🖱️ Mice
- **DPI Control:** 4 customizable DPI stages (up to 42,000 DPI), quick-switch stage pills, and stage color indicators.
- **Performance Tuning:** Polling rate selection (`125 Hz` to `8000 Hz`), Angle Snapping toggle, Lift-Off Distance (`Low 1mm` / `High 2mm`), and Button Debounce slider (`0ms` to `32ms`).
- **Aura RGB Lighting:** Modes (*Static, Breathing, Color Cycle, Rainbow, Battery State*), brightness, and color swatches.
- **Power:** Sleep timer, low battery threshold, and live battery level.
- *Supported Models:*
  - **ROG Harpe Series:** Harpe Ace Aim Lab, Harpe Ace Extreme, Harpe Ace Mini, Harpe II Ace (Wired & Wireless).
  - **ROG Keris Series:** Keris II Ace, Keris II Origin, Keris Wireless Aimpoint, Keris Wireless, Keris EVA Edition.
  - **ROG Gladius Series:** Gladius III Aimpoint (inc. EVA-02), Gladius III Wireless, Gladius II Wireless, Gladius II Origin.
  - **ROG Chakram Series:** Chakram X, Chakram, Chakram Core.
  - **ROG Spatha Series:** Spatha X.
  - **ROG Pugio & Strix Impact Series:** Pugio, Pugio II, Strix Impact I/II/III (inc. Wireless & Electro Punk).
  - **ASUS TUF Mice:** TUF M3, M3 Gen II, M4 Air, M4 Wireless, M5, TX Gaming Mini.
  - **ProArt & Accessories:** ProArt Mouse MD200, ROG Balteus & Balteus Qi RGB mousepads.

### ⌨️ Keyboards
- **Aura RGB Lighting:** Modes (*Static, Breathing, Color Cycle, Reactive, Wave, Ripple, Starry Night, Quicksand, Current, Rain Drop*), brightness slider, effect speed (*Slow, Medium, Fast*), and color picker.
- **OLED Display Controls:** Dedicated OLED toggle, brightness slider, and animation preset selector (*ROG Logo, Cyber City, Pixel Samurai, Matrix Stream, Equalizer Waves, System Info*) for OLED-equipped models.
- **Power:** Sleep timer and battery/charging status for wireless models.
- *Supported Models:*
  - **ROG Azoth Series:** Azoth, Azoth Wireless, Azoth Extreme, Azoth Extreme SE, Azoth X, Azoth Omni.
  - **ROG Falchion Series:** Falchion, Falchion Wireless, Falchion RX, Falchion Ace, Falchion Ace HFX, Falchion RX Low-Profile.
  - **ROG Strix Scope II Series:** Scope II, Scope II RX, Scope II 96 Wireless, Scope II 96 RX Wireless.
  - **ROG Strix Scope RX Series:** Scope RX TKL Wireless/Wired, Scope RX, Scope RX EVA & EVA-02.
  - **ROG Strix Flare Series:** Flare, Flare COD, Flare PNK, Flare II, Flare II Animate.
  - **ROG Claymore Series:** Claymore II.
  - **ASUS TUF Keyboards:** TUF Gaming K1, K3, K3 Gen II.

---

## 🛠️ Building & Running

### Requirements
- macOS 13.0 (Ventura), macOS 14 (Sonoma), macOS 15 (Sequoia), or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Xcode Command Line Tools (`swift`, `swiftc`)

### Compile & Package `.app`
Run the build script from the repository root:
```bash
./build_app.sh
```
This builds a Release binary and packages it into `GHelperMac.app` with icons, resource bundles, and ad-hoc code signing.

### Launching
```bash
open GHelperMac.app
```
Look for the circular G icon in your menu bar!

---

## 📜 License
Inspired by and protocol-compatible with [G-Helper](https://github.com/seerge/g-helper) by [seerge](https://github.com/seerge).
Distributed under the MIT License.
