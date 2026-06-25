import SwiftUI

// MARK: - ScrollControl App

/// Main app entry point - menu bar application with no Dock icon
@main
struct ScrollControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var monitor = GlobalScrollMonitor.shared
    @ObservedObject private var permissions = PermissionsManager.shared

    var body: some Scene {
        // Menu bar extra scene
        MenuBarExtra {
            MenuBarMenu()
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .menuBarExtraStyle(.menu)

        // Settings scene - use SettingsLink to open
        Settings {
            SettingsView()
        }
    }
}

// MARK: - App Delegate

/// Handles app lifecycle events
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var permissionCheckTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[App] 🚀 ScrollControl launched")

        // Check permissions immediately
        let granted = PermissionsManager.shared.checkAccessibility()
        print("[App] Initial permission check: \(granted)")

        if granted {
            // Auto-start monitoring if permission is already granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("[App] Permission granted, starting monitoring...")
                GlobalScrollMonitor.shared.startMonitoring()
            }
        } else {
            // Show permission alert after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("[App] Permission not granted, showing alert...")
                PermissionsManager.shared.showPermissionAlertIfNeeded()
            }

            // Start periodic permission check
            startPermissionCheckTimer()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[App] ⏹ ScrollControl terminating")
        GlobalScrollMonitor.shared.stopMonitoring()
        permissionCheckTimer?.invalidate()
    }

    // MARK: - Permission Check Timer

    private func startPermissionCheckTimer() {
        print("[App] Starting permission check timer (every 2 seconds)")

        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            let granted = PermissionsManager.shared.checkAccessibility()

            if granted {
                print("[App] ✅ Permission granted! Starting monitoring...")
                timer.invalidate()
                self?.permissionCheckTimer = nil

                DispatchQueue.main.async {
                    GlobalScrollMonitor.shared.startMonitoring()
                }
            }
        }
    }
}

// MARK: - Menu Bar Menu

/// Menu bar dropdown menu content
struct MenuBarMenu: View {
    @ObservedObject private var monitor = GlobalScrollMonitor.shared
    @ObservedObject private var permissions = PermissionsManager.shared
    @State private var volumeText: String = "50%"
    @State private var brightnessText: String = "50%"

    var body: some View {
        // Status section
        Section {
            HStack {
                Circle()
                    .fill(monitor.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(monitor.isActive ? "监听中" : "已停止")
                    .font(.caption)

                Spacer()

                if monitor.isActive {
                    Text("事件: \(monitor.eventCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text("音量: \(volumeText)")
                Spacer()
                Text("亮度: \(brightnessText)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .onAppear {
                updateValues()
            }
        }

        Divider()

        // Quick controls
        Section {
            Button(monitor.isActive ? "停止监听" : "开始监听") {
                if monitor.isActive {
                    monitor.stopMonitoring()
                } else {
                    monitor.startMonitoring()
                }
                updateValues()
            }

            // Use SettingsLink to open Settings window (macOS 14+)
            SettingsLink {
                HStack {
                    Image(systemName: "gear")
                    Text("偏好设置...")
                }
            }
            .keyboardShortcut(",", modifiers: .command)

            if !permissions.isAccessibilityGranted {
                Button("授予权限...") {
                    permissions.requestAccessibility()
                }
            }

            Button("刷新数值") {
                updateValues()
            }
        }

        Divider()

        // Quit
        Section {
            Button("退出 ScrollControl") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    private func updateValues() {
        // Update on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let vol = VolumeController.shared.volumePercentage
            let bright = BrightnessController.shared.brightnessPercentage

            DispatchQueue.main.async {
                volumeText = vol
                brightnessText = bright
            }
        }
    }
}
