import Foundation
import IOKit
import IOKit.hid
import OSLog

private let logger = Logger(subsystem: "com.ghelper.mac", category: "HIDManager")

public protocol HIDManagerDelegate: AnyObject {
    func hidDeviceConnected(device: IOHIDDevice, vendorId: Int, productId: Int)
    func hidDeviceDisconnected(device: IOHIDDevice, vendorId: Int, productId: Int)
}

public final class HIDManager {
    public static let shared = HIDManager()

    public weak var delegate: HIDManagerDelegate?

    private var manager: IOHIDManager?
    private var isRunning = false

    public static let ASUS_VENDOR_ID = 0x0B05

    private init() {}

    public func start() {
        guard !isRunning else { return }

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager

        let matchingDict: [String: Any] = [
            kIOHIDVendorIDKey: Self.ASUS_VENDOR_ID
        ]

        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)

        let context = Unmanaged.passUnretained(self).toOpaque()

        // Device Connected Callback
        let matchCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let hidManager = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
            hidManager.handleDeviceMatched(device: device)
        }

        // Device Disconnected Callback
        let removeCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let hidManager = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
            hidManager.handleDeviceRemoved(device: device)
        }

        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchCallback, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removeCallback, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)

        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if openResult != kIOReturnSuccess {
            logger.error("Failed to open IOHIDManager: \(openResult)")
            return
        }

        isRunning = true
        logger.info("IOHIDManager started and monitoring for ASUS peripherals")

        // Enumerate already plugged in devices
        scanExistingDevices()
    }

    public func stop() {
        guard isRunning, let manager = manager else { return }
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        self.manager = nil
        isRunning = false
    }

    private func scanExistingDevices() {
        guard let manager = manager else { return }
        if let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> {
            for device in deviceSet {
                handleDeviceMatched(device: device)
            }
        }
    }

    private func isVendorControlInterface(device: IOHIDDevice) -> Bool {
        let primaryUsagePage = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsagePageKey as CFString) as? Int ?? 0
        if primaryUsagePage == 0xFF00 {
            return true
        }

        // Check DeviceUsagePairs
        if let usagePairs = IOHIDDeviceGetProperty(device, kIOHIDDeviceUsagePairsKey as CFString) as? [[String: Any]] {
            for pair in usagePairs {
                if let page = pair[kIOHIDDeviceUsagePageKey] as? Int, page == 0xFF00 || page == 65280 {
                    return true
                }
            }
        }

        return false
    }

    private func handleDeviceMatched(device: IOHIDDevice) {
        let vendorId = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productId = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let productName = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown"

        guard vendorId == Self.ASUS_VENDOR_ID else { return }

        // Ensure this interface supports the vendor control page (0xFF00)
        guard isVendorControlInterface(device: device) else {
            logger.debug("Skipping non-control interface for \(productName) (PID: 0x\(String(format: "%04X", productId)))")
            return
        }

        logger.info("Control interface discovered: \(productName) (0x\(String(format: "%04X", vendorId)):0x\(String(format: "%04X", productId)))")
        delegate?.hidDeviceConnected(device: device, vendorId: vendorId, productId: productId)
    }

    private func handleDeviceRemoved(device: IOHIDDevice) {
        let vendorId = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productId = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0

        guard isVendorControlInterface(device: device) else { return }

        logger.info("Device disconnected (0x\(String(format: "%04X", vendorId)):0x\(String(format: "%04X", productId)))")
        delegate?.hidDeviceDisconnected(device: device, vendorId: vendorId, productId: productId)
    }
}
