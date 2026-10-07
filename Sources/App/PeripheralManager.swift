import Foundation
import SwiftUI
import Combine
import IOKit
import OSLog

private let logger = Logger(subsystem: "com.ghelper.mac", category: "PeripheralManager")

@MainActor
public final class PeripheralManager: ObservableObject, HIDManagerDelegate {
    public static let shared = PeripheralManager()

    @Published public var headsets: [AsusHeadset] = []
    @Published public var mice: [AsusMouse] = []
    @Published public var keyboards: [AsusKeyboard] = []
    @Published public var selectedPeripheralID: String?

    public var allPeripherals: [any AsusPeripheral] {
        var list: [any AsusPeripheral] = []
        list.append(contentsOf: headsets)
        list.append(contentsOf: mice)
        list.append(contentsOf: keyboards)
        return list
    }

    public var selectedPeripheral: (any AsusPeripheral)? {
        if let id = selectedPeripheralID {
            return allPeripherals.first(where: { $0.id == id }) ?? allPeripherals.first
        }
        return allPeripherals.first
    }

    // Legacy / Convenience accessors
    public var selectedHeadsetID: String? {
        get { selectedPeripheralID }
        set { selectedPeripheralID = newValue }
    }

    public var selectedHeadset: AsusHeadset? {
        if let h = selectedPeripheral as? AsusHeadset {
            return h
        }
        return headsets.first
    }

    public var selectedMouse: AsusMouse? {
        if let m = selectedPeripheral as? AsusMouse {
            return m
        }
        return mice.first
    }

    public var selectedKeyboard: AsusKeyboard? {
        if let k = selectedPeripheral as? AsusKeyboard {
            return k
        }
        return keyboards.first
    }

    private var pollTimer: AnyCancellable?

    public init() {
        HIDManager.shared.delegate = self
        HIDManager.shared.start()
        startPolling()
    }

    private func startPolling() {
        pollTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pollAllDevices()
            }
    }

    public func pollAllDevices() {
        for peripheral in allPeripherals {
            peripheral.pollBattery()
        }
    }

    // MARK: - HIDManagerDelegate

    public nonisolated func hidDeviceConnected(device: IOHIDDevice, vendorId: Int, productId: Int) {
        Task { @MainActor in
            let deviceID = "\(vendorId):\(productId)"

            // Check if already registered
            if self.allPeripherals.contains(where: { $0.id == deviceID }) {
                return
            }

            let session = HIDDeviceSession(device: device)

            if let mouseMeta = MouseRegistry.getMetadata(productId: productId) {
                let mouse = AsusMouse(session: session, id: deviceID, metadata: mouseMeta)
                self.mice.append(mouse)
                if self.selectedPeripheralID == nil {
                    self.selectedPeripheralID = deviceID
                }
                logger.info("Registered mouse: \(mouse.displayName) (PID: 0x\(String(format: "%04X", productId)))")
                mouse.synchronizeDevice()
            } else if let kbMeta = KeyboardRegistry.getMetadata(productId: productId) {
                let kb = AsusKeyboard(session: session, id: deviceID, metadata: kbMeta)
                self.keyboards.append(kb)
                if self.selectedPeripheralID == nil {
                    self.selectedPeripheralID = deviceID
                }
                logger.info("Registered keyboard: \(kb.displayName) (PID: 0x\(String(format: "%04X", productId)))")
                kb.synchronizeDevice()
            } else {
                // Headset family
                let headset: AsusHeadset
                switch productId {
                case ROGDeltaII.productID, ROGDeltaII.productIDKJP:
                    headset = ROGDeltaII(session: session, id: deviceID)
                case ROGPelta.productID:
                    headset = ROGPelta(session: session, id: deviceID)
                case ROGCetraSpeedNova.productID:
                    headset = ROGCetraSpeedNova(session: session, id: deviceID)
                case ROGClavis.productID:
                    headset = ROGClavis(session: session, id: deviceID)
                case ROGCetraRGB.productID, ROGCetraRGB.productID2:
                    headset = ROGCetraRGB(session: session, id: deviceID)
                case ROGStrixGo24.productID:
                    headset = ROGStrixGo24(session: session, id: deviceID)
                default:
                    headset = AsusHeadset(session: session, id: deviceID)
                }

                self.headsets.append(headset)
                if self.selectedPeripheralID == nil {
                    self.selectedPeripheralID = deviceID
                }
                logger.info("Registered headset: \(headset.displayName) (PID: 0x\(String(format: "%04X", productId)))")
                headset.synchronizeDevice()
            }
        }
    }

    public nonisolated func hidDeviceDisconnected(device: IOHIDDevice, vendorId: Int, productId: Int) {
        Task { @MainActor in
            let deviceID = "\(vendorId):\(productId)"
            self.headsets.removeAll(where: { $0.id == deviceID })
            self.mice.removeAll(where: { $0.id == deviceID })
            self.keyboards.removeAll(where: { $0.id == deviceID })

            if self.selectedPeripheralID == deviceID {
                self.selectedPeripheralID = self.allPeripherals.first?.id
            }

            logger.info("Unregistered peripheral: ID \(deviceID)")
        }
    }
}
