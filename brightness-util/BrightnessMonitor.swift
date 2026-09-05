import Foundation
import AppKit
import Combine
import CoreGraphics
import IOKit
import IOKit.graphics
import Darwin

private func symbol<T>(_ handle: UnsafeMutableRawPointer?, name: String, as type: T.Type) -> T? {
    guard let handle, let pointer = dlsym(handle, name) else {
        return nil
    }
    return unsafeBitCast(pointer, to: type)
}

private struct DisplayServicesBridge {
    typealias CanChangeBrightness = @convention(c) (UInt32) -> Bool
    typealias GetBrightness = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32

    static let shared = DisplayServicesBridge()

    let canChangeBrightness: CanChangeBrightness?
    let getBrightness: GetBrightness?

    private init() {
        let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
        canChangeBrightness = symbol(handle, name: "DisplayServicesCanChangeBrightness", as: CanChangeBrightness.self)
        getBrightness = symbol(handle, name: "DisplayServicesGetBrightness", as: GetBrightness.self)
    }
}

private struct CoreDisplayBridge {
    typealias GetUserBrightness = @convention(c) (CGDirectDisplayID) -> Double

    static let shared = CoreDisplayBridge()

    let getUserBrightness: GetUserBrightness?

    private init() {
        let handle = dlopen("/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay", RTLD_LAZY)
        getUserBrightness = symbol(handle, name: "CoreDisplay_Display_GetUserBrightness", as: GetUserBrightness.self)
    }
}

/// Reads the main display brightness using the same order of operations as nriley/brightness PR #36.
enum BrightnessReader {
    static func brightness(for displayID: CGDirectDisplayID) -> Double? {
        let uintDisplayID = UInt32(displayID)

        // Prefer DisplayServices SPI when available.
        let displayServices = DisplayServicesBridge.shared
        if let getBrightness = displayServices.getBrightness {
            let canChange = displayServices.canChangeBrightness?(uintDisplayID) ?? true
            if canChange {
                var value: Float = 0
                if getBrightness(uintDisplayID, &value) == 0, value.isFinite, (0...1).contains(value) {
                    return Double(value)
                }
            }
        }

        // Fall back to CoreDisplay SPI.
        if let getBrightness = CoreDisplayBridge.shared.getUserBrightness {
            let value = getBrightness(displayID)
            if value.isFinite, (0...1).contains(value) {
                return value
            }
        }

        // Finally use IOKit brightness parameter.
        guard let service = mainDisplayService(for: displayID) else { return nil }
        defer { IOObjectRelease(service) }

        if let registryValue = IORegistryEntryCreateCFProperty(service, kIODisplayBrightnessKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber,
           registryValue.doubleValue.isFinite, (0...1).contains(registryValue.doubleValue) {
            return registryValue.doubleValue
        }

        var brightness: Float = 0
        let status = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
        guard status == kIOReturnSuccess, brightness.isFinite, (0...1).contains(brightness) else { return nil }
        return Double(brightness)
    }

    private static func mainDisplayService(for displayID: CGDirectDisplayID) -> io_service_t? {
        var iterator = io_iterator_t()
        let matching = IOServiceMatching("IODisplayConnect")
        let err = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard err == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }

        let targetVendor = CGDisplayVendorNumber(displayID)
        let targetProduct = CGDisplayModelNumber(displayID)
        let targetSerial = CGDisplaySerialNumber(displayID)

        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }

            guard let info = IODisplayCreateInfoDictionary(service, 0).takeRetainedValue() as? [String: Any] else {
                IOObjectRelease(service)
                continue
            }

            let vendor = uint32Value(info["DisplayVendorID"]) ?? 0
            let product = uint32Value(info["DisplayProductID"]) ?? 0
            let serial = uint32Value(info["DisplaySerialNumber"]) ?? 0

            let vendorMatches = targetVendor == 0 || vendor == targetVendor
            let productMatches = targetProduct == 0 || product == targetProduct
            let serialMatches = targetSerial == 0 || serial == targetSerial

            if vendorMatches && productMatches && serialMatches {
                return service
            }

            IOObjectRelease(service)
        }

        return nil
    }

    private static func uint32Value(_ value: Any?) -> UInt32? {
        switch value {
        case let number as NSNumber:
            return number.uint32Value
        case let value as UInt32:
            return value
        case let value as Int:
            return UInt32(value)
        default:
            return nil
        }
    }
}

/// Publishes brightness updates on a timer so the menu bar stays in sync.
final class BrightnessMonitor: ObservableObject {
    @Published private(set) var brightness: Double?
    @Published private(set) var displayName = "Main Display"

    var cellCount: Int? {
        brightness.map { Int(($0 * 16).rounded()) }
    }

    private var timer: AnyCancellable?
    private let queue = DispatchQueue(label: "BrightnessMonitor")

    init(pollInterval: TimeInterval = 1.5) {
        refresh()
        timer = Timer.publish(every: pollInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    deinit {
        timer?.cancel()
    }

    private func refresh() {
        let displayID = CGMainDisplayID()
        let displayName = NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == displayID
        }?.localizedName ?? "Main Display"

        queue.async { [weak self] in
            let value = BrightnessReader.brightness(for: displayID)
            DispatchQueue.main.async {
                guard let self, CGMainDisplayID() == displayID else { return }
                if self.brightness != value { self.brightness = value }
                if self.displayName != displayName { self.displayName = displayName }
            }
        }
    }
}
