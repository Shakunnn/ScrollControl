import Foundation
import Cocoa

// MARK: - Global Scroll Monitor

/// Monitors global scroll events and routes them to volume/brightness controllers
final class GlobalScrollMonitor: ObservableObject {
    static let shared = GlobalScrollMonitor()

    @Published var isActive: Bool = false
    @Published var lastAction: String = "无"
    @Published var eventCount: Int = 0

    private var eventMonitor: Any?
    private var accumulatedDelta: CGFloat = 0
    private var throttleTimer: DispatchWorkItem?
    private let threshold: CGFloat = 0.01 // Threshold for triggering action
    private let throttleInterval: TimeInterval = 0.05 // 50ms throttle

    // User preferences
    @Published var triggerMode: TriggerMode = .modifier
    @Published var gestureType: GestureType = .twoFinger
    @Published var modifierKey: ModifierKey = .option
    @Published var edgeThreshold: CGFloat = 20.0
    @Published var leftEdgeAction: EdgeAction = .brightness
    @Published var rightEdgeAction: EdgeAction = .volume

    // Sensitivity settings
    @Published var scrollSensitivity: Float = 0.03 // Scale factor for scroll delta (lower = less sensitive)

    private init() {
        loadPreferences()
    }

    // MARK: - Preferences

    private func loadPreferences() {
        let defaults = UserDefaults.standard

        if let mode = defaults.string(forKey: "triggerMode"),
           let tMode = TriggerMode(rawValue: mode) {
            triggerMode = tMode
            print("[Preferences] Loaded triggerMode: \(tMode.rawValue)")
        } else {
            print("[Preferences] No triggerMode saved, using default: modifier")
        }

        if let gesture = defaults.string(forKey: "gestureType"),
           let gType = GestureType(rawValue: gesture) {
            gestureType = gType
        }

        if let modifier = defaults.string(forKey: "modifierKey"),
           let mKey = ModifierKey(rawValue: modifier) {
            modifierKey = mKey
        }

        let thresholdValue = defaults.float(forKey: "edgeThreshold")
        edgeThreshold = CGFloat(thresholdValue.isNaN ? 20.0 : thresholdValue)

        if let left = defaults.string(forKey: "leftEdgeAction"),
           let lAction = EdgeAction(rawValue: left) {
            leftEdgeAction = lAction
        }

        if let right = defaults.string(forKey: "rightEdgeAction"),
           let rAction = EdgeAction(rawValue: right) {
            rightEdgeAction = rAction
        }

        let sensitivity = defaults.float(forKey: "scrollSensitivity")
        // Default to 0.03 if not set, NaN, or 0
        scrollSensitivity = (sensitivity.isNaN || sensitivity == 0) ? 0.03 : sensitivity
        print("[Preferences] Loaded scrollSensitivity: \(scrollSensitivity)")
        print("[Preferences] Current triggerMode: \(triggerMode.rawValue)")
    }

    func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(triggerMode.rawValue, forKey: "triggerMode")
        defaults.set(gestureType.rawValue, forKey: "gestureType")
        defaults.set(modifierKey.rawValue, forKey: "modifierKey")
        defaults.set(Float(edgeThreshold), forKey: "edgeThreshold")
        defaults.set(leftEdgeAction.rawValue, forKey: "leftEdgeAction")
        defaults.set(rightEdgeAction.rawValue, forKey: "rightEdgeAction")
        defaults.set(scrollSensitivity, forKey: "scrollSensitivity")
    }

    // MARK: - Event Monitoring

    func startMonitoring() {
        guard !isActive else {
            print("[Monitor] Already active, skipping start")
            return
        }

        // Force refresh permission status
        let granted = PermissionsManager.shared.checkAccessibility()
        guard granted else {
            print("[Monitor] ❌ Accessibility not granted, cannot start monitoring")
            PermissionsManager.shared.showPermissionAlertIfNeeded()
            return
        }

        print("[Monitor] 🚀 Starting global scroll event monitor...")
        print("[Monitor] Mode: \(triggerMode.displayName), Gesture: \(gestureType.displayName)")

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
        }

        if eventMonitor != nil {
            print("[Monitor] ✅ Global event monitor started successfully")
        } else {
            print("[Monitor] ❌ Failed to create event monitor")
        }

        DispatchQueue.main.async {
            self.isActive = true
        }
    }

    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
            print("[Monitor] ⏹ Event monitor stopped")
        }
        throttleTimer?.cancel()
        accumulatedDelta = 0

        DispatchQueue.main.async {
            self.isActive = false
        }
    }

    // MARK: - Event Handling

    private func handleScrollEvent(_ event: NSEvent) {
        // Try both continuous and discrete scroll deltas
        let continuousDeltaY = event.scrollingDeltaY
        let discreteDeltaY = event.deltaY
        let deltaY = continuousDeltaY != 0 ? continuousDeltaY : discreteDeltaY

        // Use global modifier flags instead of event's modifier flags
        let modifierFlags = NSEvent.modifierFlags
        let mouseLocation = NSEvent.mouseLocation

        // Debug: Print event info (throttled to avoid spam)
        eventCount += 1
        if eventCount % 3 == 1 {
            print("[Monitor] 📜 Scroll event #\(eventCount):")
            print("[Monitor]   continuousDeltaY=\(String(format: "%.6f", continuousDeltaY)), discreteDeltaY=\(String(format: "%.6f", discreteDeltaY))")
            print("[Monitor]   using deltaY=\(String(format: "%.6f", deltaY))")
            print("[Monitor]   modifiers=\(modifierFlags.rawValue), mouse=\(mouseLocation)")
            print("[Monitor]   Option: \(modifierFlags.contains(.option)), Command: \(modifierFlags.contains(.command))")
            print("[Monitor]   triggerMode: \(triggerMode.rawValue)")
        }

        // Determine action based on trigger mode
        var action: EdgeAction?
        var actionSource: String = ""

        switch triggerMode {
        case .modifier:
            action = handleModifierMode(deltaY: deltaY, modifierFlags: modifierFlags)
            if action != nil { actionSource = "modifier" }

        case .edge:
            action = handleEdgeMode(deltaY: deltaY, mouseLocation: mouseLocation)
            if action != nil { actionSource = "edge" }
        }

        guard let targetAction = action else {
            if eventCount % 50 == 1 {
                print("[Monitor] ⚠️ No action triggered (mode: \(triggerMode.rawValue))")
            }
            return
        }

        print("[Monitor] 🎯 Action: \(targetAction.displayName) via \(actionSource), deltaY=\(String(format: "%.6f", deltaY))")

        // Accumulate delta and apply with throttling
        accumulatedDelta += deltaY
        print("[Monitor] 📊 Accumulated delta: \(String(format: "%.6f", accumulatedDelta))")
        applyWithThrottling(action: targetAction)
    }

    // MARK: - Modifier Key Mode

    private func handleModifierMode(deltaY: CGFloat, modifierFlags: NSEvent.ModifierFlags) -> EdgeAction? {
        // Check for Option key (Volume control)
        let hasOption = modifierFlags.contains(.option)
        // Check for Command key (Brightness control)
        let hasCommand = modifierFlags.contains(.command)
        // Check for Control key
        let hasControl = modifierFlags.contains(.control)
        // Check for Shift key
        let hasShift = modifierFlags.contains(.shift)

        // Debug: Log which modifiers are detected
        if eventCount % 10 == 1 {
            print("[Monitor] 🔑 Modifiers - Option: \(hasOption), Command: \(hasCommand), Control: \(hasControl), Shift: \(hasShift)")
        }

        // Priority: Option > Command > selected modifier key
        if hasOption {
            print("[Monitor] ✅ Option key detected → Volume control")
            return .volume
        }

        if hasCommand {
            print("[Monitor] ✅ Command key detected → Brightness control")
            return .brightness
        }

        // Fallback: check the user-selected modifier key
        let hasSelectedModifier: Bool
        switch modifierKey {
        case .option:
            hasSelectedModifier = hasOption
        case .command:
            hasSelectedModifier = hasCommand
        case .control:
            hasSelectedModifier = hasControl
        case .shift:
            hasSelectedModifier = hasShift
        }

        if hasSelectedModifier {
            print("[Monitor] ✅ Selected modifier key \(modifierKey.displayName) detected → Volume control")
            return .volume
        }

        print("[Monitor] ⚠️ No modifier key pressed")
        return nil
    }

    // MARK: - Screen Edge Mode

    private func handleEdgeMode(deltaY: CGFloat, mouseLocation: NSPoint) -> EdgeAction? {
        // Get the screen containing the mouse
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else {
            print("[Edge] ❌ No screen found for mouse location: \(mouseLocation)")
            return nil
        }

        let screenFrame = screen.frame
        let mouseX = mouseLocation.x
        let mouseY = mouseLocation.y

        // Debug: Print edge detection info
        if eventCount % 10 == 1 {
            print("[Edge] 🔍 Mouse: (\(String(format: "%.1f", mouseX)), \(String(format: "%.1f", mouseY)))")
            print("[Edge] 🔍 Screen frame: \(screenFrame)")
            print("[Edge] 🔍 Left edge: \(screenFrame.minX) to \(screenFrame.minX + edgeThreshold)")
            print("[Edge] 🔍 Right edge: \(screenFrame.maxX - edgeThreshold) to \(screenFrame.maxX)")
        }

        // Check left edge
        if mouseX <= screenFrame.minX + edgeThreshold {
            print("[Edge] ✅ Left edge detected! mouseX=\(String(format: "%.1f", mouseX)), threshold=\(edgeThreshold)")
            return leftEdgeAction
        }

        // Check right edge
        if mouseX >= screenFrame.maxX - edgeThreshold {
            print("[Edge] ✅ Right edge detected! mouseX=\(String(format: "%.1f", mouseX)), threshold=\(edgeThreshold)")
            return rightEdgeAction
        }

        if eventCount % 10 == 1 {
            print("[Edge] ⚠️ Not at edge. mouseX=\(String(format: "%.1f", mouseX)), leftEdge=\(String(format: "%.1f", screenFrame.minX + edgeThreshold)), rightEdge=\(String(format: "%.1f", screenFrame.maxX - edgeThreshold))")
        }

        return nil
    }

    // MARK: - Throttling

    private func applyWithThrottling(action: EdgeAction) {
        // Cancel existing timer
        throttleTimer?.cancel()

        // Check if accumulated delta exceeds threshold
        guard abs(accumulatedDelta) >= threshold else {
            print("[Monitor] ⏳ Accumulating delta: \(String(format: "%.4f", accumulatedDelta)) (threshold: \(threshold))")
            return
        }

        let delta = accumulatedDelta
        accumulatedDelta = 0

        // Apply immediately
        applyAction(action, delta: delta)

        // Update UI
        DispatchQueue.main.async {
            self.lastAction = "\(action.displayName): \(String(format: "%.2f", delta * 100))%"
        }

        // Set throttle timer to prevent rapid re-triggering
        let timer = DispatchWorkItem { [weak self] in
            self?.accumulatedDelta = 0
        }
        throttleTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + throttleInterval, execute: timer)
    }

    private func applyAction(_ action: EdgeAction, delta: CGFloat) {
        let floatDelta = Float(delta)
        // Invert delta for natural scrolling: scroll up = increase, scroll down = decrease
        let invertedDelta = -floatDelta
        let scaledDelta = invertedDelta * scrollSensitivity
        print("[Monitor] ⚡ Applying \(action.displayName) adjustment:")
        print("[Monitor]   delta=\(String(format: "%.6f", delta)), sensitivity=\(scrollSensitivity)")
        print("[Monitor]   invertedDelta=\(String(format: "%.6f", invertedDelta)), scaledDelta=\(String(format: "%.6f", scaledDelta))")

        switch action {
        case .volume:
            VolumeController.shared.adjust(by: scaledDelta)
            print("[Monitor] 🔊 Volume: \(VolumeController.shared.volumePercentage)")
        case .brightness:
            BrightnessController.shared.adjust(by: scaledDelta)
            print("[Monitor] 🔆 Brightness: \(BrightnessController.shared.brightnessPercentage)")
        }
    }

    // MARK: - Force Start (for debugging)

    /// Force start monitoring without permission check (for testing)
    func forceStartMonitoring() {
        guard !isActive else { return }

        print("[Monitor] ⚠️ Force starting monitoring (bypassing permission check)")

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
        }

        let success = eventMonitor != nil
        DispatchQueue.main.async {
            self.isActive = success
        }
    }

    // MARK: - Cleanup

    deinit {
        stopMonitoring()
    }
}
