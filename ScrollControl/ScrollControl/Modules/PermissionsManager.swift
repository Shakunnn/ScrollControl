import Foundation
import Cocoa
import ApplicationServices

// MARK: - Permissions Manager

/// Manages accessibility permissions required for global event monitoring
final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published var isAccessibilityGranted: Bool = false

    private init() {
        checkAccessibility()
    }

    /// Check current accessibility permission status
    @discardableResult
    func checkAccessibility() -> Bool {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.isAccessibilityGranted = trusted
        }
        print("[Permissions] Accessibility granted: \(trusted)")
        return trusted
    }

    /// Request accessibility permissions with a prompt dialog
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.async {
            self.isAccessibilityGranted = granted
        }
        print("[Permissions] Request result: \(granted)")
    }

    /// Show alert guiding user to System Settings if permission is not granted
    func showPermissionAlertIfNeeded() {
        guard !isAccessibilityGranted else { return }

        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "ScrollControl 需要辅助功能权限才能在后台监听滚动事件。\n\n请在「系统设置 → 隐私与安全性 → 辅助功能」中启用 ScrollControl。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后设置")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    /// Open System Settings to the Accessibility pane
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Periodically check for permission changes
    func startPermissionCheck() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAccessibility()
        }
    }
}
