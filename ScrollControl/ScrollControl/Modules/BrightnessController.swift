import Foundation
import AppKit
import CoreGraphics

// MARK: - Brightness Controller

/// Controls display brightness using DisplayServices private framework
final class BrightnessController {
    static let shared = BrightnessController()

    private var lastBrightness: Float = 0.5

    // DisplayServices function types
    private typealias DisplayServicesGetBrightnessType = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> CGError
    private typealias DisplayServicesSetBrightnessType = @convention(c) (CGDirectDisplayID, Float) -> CGError
    private typealias DisplayServicesCanChangeBrightnessType = @convention(c) (CGDirectDisplayID) -> Bool

    private let displayServicesBundle: CFBundle? = {
        let bundleURL = CFURLCreateWithString(
            nil,
            "/System/Library/PrivateFrameworks/DisplayServices.framework" as CFString,
            nil
        )
        guard let url = bundleURL else { return nil }
        return CFBundleCreate(nil, url)
    }()

    private init() {
        // Cache initial brightness
        lastBrightness = readBrightness()
        print("[Brightness] Initial brightness: \(Int(lastBrightness * 100))%")
    }

    // MARK: - DisplayServices Functions

    private func getFunction<T>(_ name: String) -> T? {
        guard let bundle = displayServicesBundle else {
            print("[Brightness] ❌ DisplayServices bundle not found")
            return nil
        }
        let cfName = name as CFString
        guard let pointer = CFBundleGetFunctionPointerForName(bundle, cfName) else {
            print("[Brightness] ❌ Function \(name) not found")
            return nil
        }
        return unsafeBitCast(pointer, to: T.self)
    }

    // MARK: - Brightness Control

    private func readBrightness() -> Float {
        var brightness: Float = lastBrightness

        let getBrightness: DisplayServicesGetBrightnessType? = getFunction("DisplayServicesGetBrightness")
        guard let getFn = getBrightness else {
            print("[Brightness] ⚠️ Using cached brightness: \(Int(lastBrightness * 100))%")
            return lastBrightness
        }

        let displayID = CGMainDisplayID()
        let err = getFn(displayID, &brightness)

        if err == .success {
            lastBrightness = brightness
            print("[Brightness] ✅ Read brightness: \(Int(brightness * 100))%")
        } else {
            print("[Brightness] ⚠️ Failed to read brightness: \(err.rawValue)")
        }

        return brightness
    }

    private func writeBrightness(_ value: Float) {
        let newBrightness = max(0.0, min(1.0, value))

        let setBrightness: DisplayServicesSetBrightnessType? = getFunction("DisplayServicesSetBrightness")
        guard let setFn = setBrightness else {
            print("[Brightness] ❌ DisplayServicesSetBrightness not available")
            return
        }

        let displayID = CGMainDisplayID()
        let err = setFn(displayID, newBrightness)

        if err == .success {
            lastBrightness = newBrightness
            print("[Brightness] ✅ Set brightness to \(Int(newBrightness * 100))%")
        } else {
            print("[Brightness] ❌ Failed to set brightness: \(err.rawValue)")
        }
    }

    // MARK: - Public Interface

    /// Get current brightness (0.0 ~ 1.0)
    var brightness: Float {
        get {
            return readBrightness()
        }
        set {
            writeBrightness(newValue)
        }
    }

    /// Adjust brightness by delta (positive = brighter, negative = dimmer)
    func adjust(by delta: Float) {
        let current = brightness
        let newBrightness = current + delta
        print("[Brightness] Adjust: \(String(format: "%.1f", current * 100))% → \(String(format: "%.1f", newBrightness * 100))%")
        brightness = newBrightness
    }

    /// Get brightness as percentage string for display
    var brightnessPercentage: String {
        "\(Int(brightness * 100))%"
    }
}
