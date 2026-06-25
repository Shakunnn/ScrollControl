import Foundation

// MARK: - Volume Controller

/// Controls system volume using AppleScript
final class VolumeController {
    static let shared = VolumeController()

    private var cachedVolume: Float = 0.5

    private init() {
        // Read initial volume
        cachedVolume = readVolume()
        print("[Volume] Initial volume: \(Int(cachedVolume * 100))%")
    }

    // MARK: - Volume Control via AppleScript

    /// Read system volume using AppleScript (0.0 ~ 1.0)
    private func readVolume() -> Float {
        let script = "output volume of (get volume settings)"
        var error: NSDictionary?

        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if let error = error {
                print("[Volume] ❌ Read error: \(error)")
                return cachedVolume
            }
            let volume = Float(result.int32Value) / 100.0
            cachedVolume = volume
            print("[Volume] 📖 Read volume: \(Int(volume * 100))%")
            return volume
        }

        print("[Volume] ❌ Failed to create AppleScript for reading")
        return cachedVolume
    }

    /// Set system volume using AppleScript (0.0 ~ 1.0)
    private func writeVolume(_ volume: Float) {
        let newVolume = max(0.0, min(1.0, volume))
        let volumePercent = Int(newVolume * 100)

        print("[Volume] 📝 Setting volume to \(volumePercent)%...")

        let script = "set volume output volume \(volumePercent)"
        var error: NSDictionary?

        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("[Volume] ❌ Write error: \(error)")
            } else {
                cachedVolume = newVolume
                print("[Volume] ✅ Set volume to \(volumePercent)%")

                // Verify by reading back
                let readBack = readVolume()
                print("[Volume] 🔍 Read back after set: \(Int(readBack * 100))%")
            }
        } else {
            print("[Volume] ❌ Failed to create AppleScript for writing")
        }
    }

    // MARK: - Public Interface

    /// Get current volume (0.0 ~ 1.0)
    var volume: Float {
        get {
            return readVolume()
        }
        set {
            writeVolume(newValue)
        }
    }

    /// Adjust volume by delta (positive = louder, negative = quieter)
    func adjust(by delta: Float) {
        let currentVolume = volume
        let newVolume = currentVolume + delta
        print("[Volume] ⚡ Adjust: \(String(format: "%.1f", currentVolume * 100))% → \(String(format: "%.1f", newVolume * 100))%")
        volume = newVolume
    }

    /// Get volume as percentage string for display
    var volumePercentage: String {
        "\(Int(volume * 100))%"
    }
}
