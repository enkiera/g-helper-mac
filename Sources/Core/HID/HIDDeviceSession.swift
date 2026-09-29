import Foundation
import IOKit
import IOKit.hid
import OSLog

private let logger = Logger(subsystem: "com.ghelper.mac", category: "HIDDeviceSession")

public final class HIDDeviceSession {
    private let device: IOHIDDevice
    private let packetSize: Int
    private let queue = DispatchQueue(label: "com.ghelper.mac.hid.session", qos: .userInitiated)
    private var reportBuffer: UnsafeMutablePointer<UInt8>
    private var isRegistered = false

    private let responseSemaphore = DispatchSemaphore(value: 0)
    private var expectedCmd: (UInt8, UInt8)?
    private var pendingResponse: [UInt8]?

    public init(device: IOHIDDevice, packetSize: Int = 64) {
        self.device = device
        self.packetSize = packetSize
        self.reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: packetSize)
        setupInputCallback()
    }

    deinit {
        if isRegistered {
            IOHIDDeviceRegisterInputReportCallback(device, reportBuffer, packetSize, nil, nil)
            IOHIDDeviceUnscheduleFromRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        }
        reportBuffer.deallocate()
    }

    private func setupInputCallback() {
        let context = Unmanaged.passUnretained(self).toOpaque()

        let callback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
            guard let context = context else { return }
            let session = Unmanaged<HIDDeviceSession>.fromOpaque(context).takeUnretainedValue()
            session.handleInputReport(report: report, length: reportLength)
        }

        IOHIDDeviceRegisterInputReportCallback(device, reportBuffer, packetSize, callback, context)
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        isRegistered = true
    }

    private func handleInputReport(report: UnsafePointer<UInt8>, length: CFIndex) {
        let buffer = Array(UnsafeBufferPointer(start: report, count: length))
        
        let hex = buffer.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")
        logger.debug("HID IN: \(hex, privacy: .public)")

        guard buffer.count >= 3 else { return }

        // Check if waiting for a response
        if let expected = expectedCmd {
            let cmd1 = buffer[1]
            let cmd2 = buffer[2]

            // Check for NAK
            if (cmd1 == 0xFF && cmd2 == 0xAA) || (buffer.count >= 7 && buffer[5] == 0xFF && buffer[6] == 0xAA) {
                logger.debug("Received NAK from device")
                pendingResponse = nil
                expectedCmd = nil
                responseSemaphore.signal()
                return
            }

            // Check for matching command echo
            if cmd1 == expected.0 && cmd2 == expected.1 {
                pendingResponse = buffer
                expectedCmd = nil
                responseSemaphore.signal()
            }
        }
    }

    public func writeForResponse(packet: [UInt8], timeout: TimeInterval = 2.0) -> [UInt8]? {
        return queue.sync {
            var fullPacket = packet
            if fullPacket.count < packetSize {
                fullPacket.append(contentsOf: [UInt8](repeating: 0, count: packetSize - fullPacket.count))
            } else if fullPacket.count > packetSize {
                fullPacket = Array(fullPacket.prefix(packetSize))
            }

            guard fullPacket.count >= 3 else { return nil }

            let hexOut = fullPacket.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")
            logger.debug("HID OUT: \(hexOut, privacy: .public)")

            // Set expectation
            expectedCmd = (fullPacket[1], fullPacket[2])
            pendingResponse = nil

            let reportID = CFIndex(fullPacket[0])
            let result = IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeOutput,
                reportID,
                fullPacket,
                fullPacket.count
            )

            if result != kIOReturnSuccess {
                // Fallback to Feature report if Output is rejected
                let featResult = IOHIDDeviceSetReport(
                    device,
                    kIOHIDReportTypeFeature,
                    reportID,
                    fullPacket,
                    fullPacket.count
                )
                if featResult != kIOReturnSuccess {
                    logger.error("Failed to write HID report: \(String(format: "0x%08X", result))")
                    expectedCmd = nil
                    return nil
                }
            }

            // Wait for response or timeout
            let waitResult = responseSemaphore.wait(timeout: .now() + timeout)
            if waitResult == .timedOut {
                logger.warning("Timed out waiting for HID response")
                expectedCmd = nil
                return nil
            }

            return pendingResponse
        }
    }

    public func writeFireAndForget(packet: [UInt8]) {
        queue.async {
            var fullPacket = packet
            if fullPacket.count < self.packetSize {
                fullPacket.append(contentsOf: [UInt8](repeating: 0, count: self.packetSize - fullPacket.count))
            } else if fullPacket.count > self.packetSize {
                fullPacket = Array(fullPacket.prefix(self.packetSize))
            }

            let reportID = CFIndex(fullPacket[0])
            _ = IOHIDDeviceSetReport(
                self.device,
                kIOHIDReportTypeOutput,
                reportID,
                fullPacket,
                fullPacket.count
            )
        }
    }
}
