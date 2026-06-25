import SwiftUI

// MARK: - Settings View

/// Settings window for configuring ScrollControl preferences
struct SettingsView: View {
    @ObservedObject private var monitor = GlobalScrollMonitor.shared
    @ObservedObject private var permissions = PermissionsManager.shared
    @State private var selectedTriggerMode: TriggerMode = .modifier

    var body: some View {
        TabView {
            // Tab 1: Trigger Settings
            triggerSettingsTab
                .tabItem {
                    Label("触发设置", systemImage: "hand.tap")
                }

            // Tab 2: Gesture Settings
            gestureSettingsTab
                .tabItem {
                    Label("手势设置", systemImage: "hand.draw")
                }

            // Tab 3: Status & Debug
            statusTab
                .tabItem {
                    Label("状态", systemImage: "info.circle")
                }
        }
        .frame(width: 520, height: 580)
        .onAppear {
            selectedTriggerMode = monitor.triggerMode
        }
        .onChange(of: monitor.triggerMode) { newMode in
            selectedTriggerMode = newMode
            monitor.savePreferences()
        }
        .onChange(of: monitor.gestureType) { monitor.savePreferences() }
        .onChange(of: monitor.modifierKey) { monitor.savePreferences() }
        .onChange(of: monitor.edgeThreshold) { monitor.savePreferences() }
        .onChange(of: monitor.leftEdgeAction) { monitor.savePreferences() }
        .onChange(of: monitor.rightEdgeAction) { monitor.savePreferences() }
        .onChange(of: monitor.scrollSensitivity) { monitor.savePreferences() }
    }

    // MARK: - Tab 1: Trigger Settings

    private var triggerSettingsTab: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                Text("触发方式设置")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("选择如何触发音量/亮度调节")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Permission Status
            permissionSection

            Divider()

            // Trigger Mode Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("触发模式")
                    .font(.headline)

                // Modifier Key Mode
                TriggerModeCard(
                    mode: .modifier,
                    isSelected: selectedTriggerMode == .modifier,
                    icon: "command",
                    details: "按住修饰键 + 滑动触控板"
                ) {
                    selectedTriggerMode = .modifier
                    monitor.triggerMode = .modifier
                    monitor.savePreferences()
                    print("[Settings] Trigger mode changed to: modifier")
                }

                // Edge Mode
                TriggerModeCard(
                    mode: .edge,
                    isSelected: selectedTriggerMode == .edge,
                    icon: "rectangle.leftthird.inset.filled",
                    details: "在屏幕边缘滑动触控板"
                ) {
                    selectedTriggerMode = .edge
                    monitor.triggerMode = .edge
                    monitor.savePreferences()
                    print("[Settings] Trigger mode changed to: edge")
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Tab 2: Gesture Settings

    private var gestureSettingsTab: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                Text("手势设置")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("自定义滑动手势和触发键")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // Edge Settings (only show in edge mode)
                    if selectedTriggerMode == .edge {
                        edgeSettingsSection
                        Divider()
                    }

                    // Sensitivity Settings
                    sensitivitySection
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Tab 3: Status & Debug

    private var statusTab: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                Text("状态信息")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("当前运行状态和调试信息")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 16) {
                // Monitor Status
                statusSection

                Divider()

                // Current Values
                currentValuesSection

                Divider()

                // Debug Info
                debugSection
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Permission Section

    private var permissionSection: some View {
        HStack {
            Image(systemName: permissions.isAccessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(permissions.isAccessibilityGranted ? .green : .red)
            Text(permissions.isAccessibilityGranted ? "辅助功能权限已授予" : "辅助功能权限未授予")
                .font(.subheadline)

            Spacer()

            if !permissions.isAccessibilityGranted {
                Button("授予权限") {
                    permissions.requestAccessibility()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("打开系统设置") {
                    permissions.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Gesture Type Section

    private var gestureTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("滑动手势")
                .font(.headline)

            HStack(spacing: 16) {
                // Two Finger
                GestureTypeCard(
                    gestureType: .twoFinger,
                    isSelected: monitor.gestureType == .twoFinger
                ) {
                    monitor.gestureType = .twoFinger
                }

                // Three Finger
                GestureTypeCard(
                    gestureType: .threeFinger,
                    isSelected: monitor.gestureType == .threeFinger
                ) {
                    monitor.gestureType = .threeFinger
                }
            }

            Text("提示: 三指滑动可能与其他手势冲突，请谨慎选择")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }

    // MARK: - Modifier Key Section

    private var modifierKeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("触发修饰键")
                .font(.headline)

            Text("选择按住哪个键时滑动触控板来调节")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ModifierKey.allCases) { key in
                    ModifierKeyCard(
                        modifierKey: key,
                        isSelected: monitor.modifierKey == key
                    ) {
                        monitor.modifierKey = key
                    }
                }
            }

            // Current binding display
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("当前绑定: \(monitor.modifierKey.displayName) + \(monitor.gestureType.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Edge Settings Section

    private var edgeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("屏幕边缘设置")
                .font(.headline)

            // Edge threshold
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("边缘检测范围")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(monitor.edgeThreshold)) pt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Slider(value: $monitor.edgeThreshold, in: 10...50, step: 5)
                    .accentColor(.accentColor)
            }

            // Edge actions
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "rectangle.leftthird.inset.filled")
                            .foregroundColor(.blue)
                        Text("左边缘")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Picker("", selection: $monitor.leftEdgeAction) {
                        ForEach(EdgeAction.allCases) { action in
                            HStack {
                                Image(systemName: action.icon)
                                Text(action.displayName)
                            }
                            .tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "rectangle.rightthird.inset.filled")
                            .foregroundColor(.orange)
                        Text("右边缘")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Picker("", selection: $monitor.rightEdgeAction) {
                        ForEach(EdgeAction.allCases) { action in
                            HStack {
                                Image(systemName: action.icon)
                                Text(action.displayName)
                            }
                            .tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
            }

            Text("提示: 将鼠标移动到屏幕边缘，然后\(monitor.gestureType.displayName)")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }

    // MARK: - Sensitivity Section

    private var sensitivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("灵敏度设置")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("滑动灵敏度")
                        .font(.subheadline)
                    Spacer()
                    Text("\(String(format: "%.1f", monitor.scrollSensitivity))x")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Slider(value: $monitor.scrollSensitivity, in: 0.01...0.5, step: 0.01)
                    .accentColor(.accentColor)

                HStack {
                    Text("低灵敏度")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("高灵敏度")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text("提示: 灵敏度越高，滑动时变化越明显")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(monitor.isActive ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                Text(monitor.isActive ? "监听中 ●" : "已停止 ○")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button(monitor.isActive ? "停止监听" : "开始监听") {
                    if monitor.isActive {
                        monitor.stopMonitoring()
                    } else {
                        monitor.startMonitoring()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            // Force start button (debug)
            if permissions.isAccessibilityGranted && !monitor.isActive {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("如果权限已授予但监听未启动，点击:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("强制启动") {
                        monitor.forceStartMonitoring()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Current Values Section

    private var currentValuesSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("音量")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(VolumeController.shared.volumePercentage)
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("亮度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(BrightnessController.shared.brightnessPercentage)
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("事件计数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(monitor.eventCount)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
    }

    // MARK: - Debug Section

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("调试信息")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 4) {
                DebugRow(label: "权限状态", value: permissions.isAccessibilityGranted ? "已授予" : "未授予")
                DebugRow(label: "监听状态", value: monitor.isActive ? "活跃" : "未活跃")
                DebugRow(label: "触发模式", value: monitor.triggerMode.displayName)
                DebugRow(label: "手势类型", value: monitor.gestureType.displayName)
                DebugRow(label: "触发键", value: monitor.modifierKey.displayName)
                DebugRow(label: "灵敏度", value: "\(String(format: "%.2f", monitor.scrollSensitivity))x")
                DebugRow(label: "事件总数", value: "\(monitor.eventCount)")
            }

            if monitor.lastAction != "无" {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("最后操作: \(monitor.lastAction)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Supporting Views

/// Card for trigger mode selection
struct TriggerModeCard: View {
    let mode: TriggerMode
    let isSelected: Bool
    let icon: String
    let details: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text(details)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(16)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

/// Card for gesture type selection
struct GestureTypeCard: View {
    let gestureType: GestureType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: gestureType.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .accentColor)

                Text(gestureType.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

/// Card for modifier key selection
struct ModifierKeyCard: View {
    let modifierKey: ModifierKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(modifierKey.symbol)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .accentColor)

                Text(modifierKey.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

/// Debug info row
struct DebugRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption2)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
