# ScrollControl

一款 macOS 菜单栏应用，允许用户通过触控板双指滑动结合修饰键或屏幕边缘检测，来调节系统音量和屏幕亮度。

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License: MIT">
</p>

## ✨ 功能特性

- **菜单栏应用**：无 Dock 图标，纯后台运行
- **两种触发模式**：
  - **修饰键模式**：按住 Option/Command 键 + 双指滑动
  - **屏幕边缘模式**：在屏幕左右边缘双指滑动
- **自定义设置**：
  - 可选择左边缘/右边缘对应的功能（音量/亮度）
  - 可调节边缘检测范围（10pt ~ 50pt）
  - 可调节滑动灵敏度
- **权限管理**：自动检测并引导用户授予辅助功能权限

## 📦 安装

### 方式一：下载 Release

1. 前往 [Releases](https://github.com/yourusername/ScrollControl/releases) 页面
2. 下载最新版本的 `ScrollControl.app.zip`
3. 解压后将 `ScrollControl.app` 拖入「应用程序」文件夹
4. 首次运行时，系统会提示授予辅助功能权限

### 方式二：源码编译

```bash
git clone https://github.com/yourusername/ScrollControl.git
cd ScrollControl
open ScrollControl.xcodeproj
```

在 Xcode 中选择「My Mac」作为目标设备，然后点击运行按钮 (⌘R)。

## 🚀 使用方法

### 基本操作

| 操作 | 功能 |
|------|------|
| `⌥ Option` + 双指上滑 | 音量增加 |
| `⌥ Option` + 双指下滑 | 音量减少 |
| `⌘ Command` + 双指上滑 | 亮度增加 |
| `⌘ Command` + 双指下滑 | 亮度减少 |

### 屏幕边缘模式

| 操作 | 功能 |
|------|------|
| 屏幕左边缘 + 双指滑动 | 调节亮度 |
| 屏幕右边缘 + 双指滑动 | 调节音量 |

### 快捷键

- `⌘,`：打开偏好设置
- `⌘Q`：退出应用

## ⚙️ 设置说明

点击菜单栏图标 → **偏好设置** 可配置：

### 触发设置 Tab
- 选择触发模式（修饰键/屏幕边缘）
- 查看权限状态

### 手势设置 Tab
- **修饰键模式**：调节滑动灵敏度
- **屏幕边缘模式**：设置左右边缘功能、边缘检测范围、灵敏度

### 状态 Tab
- 查看监听状态
- 查看当前音量/亮度
- 查看事件计数和调试信息

## 🔧 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- 辅助功能权限（用于全局事件监听）

## 📝 注意事项

1. **辅助功能权限**：应用必须获得辅助功能权限才能监听全局事件
2. **亮度控制**：仅支持内置显示器亮度调节
3. **音量控制**：控制系统默认输出设备的音量
4. **性能优化**：已内置节流机制（50ms），避免过度频繁的硬件调用

## 🐛 故障排除

### 权限问题
如果应用无法监听事件：
1. 打开 系统设置 → 隐私与安全性 → 辅助功能
2. 确保 ScrollControl 已启用
3. 如果没有显示，点击 "+" 添加应用

### 亮度无法调节
- 仅支持 MacBook 内置显示器
- 外接显示器需要使用显示器自带的控制方式

### 音量无法调节
- 检查系统默认输出设备是否正确
- 尝试重启应用

## 🛠️ 技术实现

- **全局事件监听**：`NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel)`
- **音量控制**：AppleScript (`set volume output volume X`)
- **亮度控制**：DisplayServices 私有框架
- **权限检查**：`AXIsProcessTrustedWithOptions`
- **节流处理**：50ms 节流 + 累积阈值

## 📁 项目结构

```
ScrollControl/
├── ScrollControl.xcodeproj/        # Xcode 项目
├── ScrollControl/
│   ├── ScrollControlApp.swift      # App 入口 (MenuBarExtra)
│   ├── Info.plist                  # LSUIElement=true (隐藏Dock图标)
│   ├── Assets.xcassets/            # 应用图标资源
│   └── Modules/
│       ├── TriggerMode.swift           # 触发模式枚举
│       ├── PermissionsManager.swift    # 辅助功能权限管理
│       ├── VolumeController.swift      # AppleScript 音量控制
│       ├── BrightnessController.swift  # DisplayServices 亮度控制
│       ├── GlobalScrollMonitor.swift   # 全局事件监听与路由
│       └── SettingsView.swift          # 设置窗口 UI
└── README.md
```

## 📄 许可证

MIT License

## 🙏 致谢

- 感谢 Apple 提供的 SwiftUI 和 macOS API
- 感谢开源社区的灵感和参考

---

如有问题或建议，欢迎提交 [Issue](https://github.com/yourusername/ScrollControl/issues) 或 [Pull Request](https://github.com/yourusername/ScrollControl/pulls)。
