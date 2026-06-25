import Foundation

// MARK: - Trigger Mode

/// Defines how scroll gestures trigger volume/brightness adjustments
enum TriggerMode: String, CaseIterable, Identifiable {
    case modifier = "modifier"   // Modifier key + scroll
    case edge = "edge"           // Screen edge + scroll

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .modifier: return "修饰键模式"
        case .edge: return "屏幕边缘模式"
        }
    }

    var description: String {
        switch self {
        case .modifier: return "按住修饰键 + 双指/三指滑动调节"
        case .edge: return "在屏幕左右边缘双指/三指滑动调节"
        }
    }
}

// MARK: - Gesture Type

/// Defines the number of fingers used for scrolling
enum GestureType: String, CaseIterable, Identifiable {
    case twoFinger = "twoFinger"
    case threeFinger = "threeFinger"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twoFinger: return "双指滑动"
        case .threeFinger: return "三指滑动"
        }
    }

    var icon: String {
        switch self {
        case .twoFinger: return "hand.point.up.left"
        case .threeFinger: return "hand.point.up.left.fill"
        }
    }
}

// MARK: - Modifier Key

/// Defines available modifier keys for triggering
enum ModifierKey: String, CaseIterable, Identifiable {
    case option = "option"
    case command = "command"
    case control = "control"
    case shift = "shift"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .option: return "⌥ Option"
        case .command: return "⌘ Command"
        case .control: return "⌃ Control"
        case .shift: return "⇧ Shift"
        }
    }

    var symbol: String {
        switch self {
        case .option: return "⌥"
        case .command: return "⌘"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }
}

// MARK: - Edge Action

/// Defines what action to perform when scrolling at screen edge
enum EdgeAction: String, CaseIterable, Identifiable {
    case volume = "volume"
    case brightness = "brightness"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .volume: return "调节音量"
        case .brightness: return "调节亮度"
        }
    }

    var icon: String {
        switch self {
        case .volume: return "speaker.wave.2"
        case .brightness: return "sun.max"
        }
    }
}
