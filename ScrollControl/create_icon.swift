#!/usr/bin/env swift

import Cocoa
import Foundation

// Simple script to generate a basic app icon
// Run: swift create_icon.swift

let size = 512
let iconSize = NSSize(width: size, height: size)

func createIcon() -> NSImage? {
    let image = NSImage(size: iconSize)
    image.lockFocus()

    // Background
    let bgColor = NSColor.systemBlue
    bgColor.setFill()
    let backgroundPath = NSBezierPath(roundedRect: NSRect(origin: .zero, size: iconSize), xRadius: 80, yRadius: 80)
    backgroundPath.fill()

    // Slider icon
    let iconColor = NSColor.white
    iconColor.setStroke()
    iconColor.setFill()

    let lineWidth: CGFloat = 12
    let sliderWidth: CGFloat = 280
    let sliderHeight: CGFloat = 8
    let sliderX = (CGFloat(size) - sliderWidth) / 2
    let sliderY = CGFloat(size) / 2 - sliderHeight / 2

    // Slider track
    let trackPath = NSBezierPath(roundedRect: NSRect(x: sliderX, y: sliderY, width: sliderWidth, height: sliderHeight), xRadius: 4, yRadius: 4)
    trackPath.lineWidth = lineWidth
    trackPath.stroke()

    // Slider knob
    let knobSize: CGFloat = 40
    let knobX = sliderX + sliderWidth * 0.6
    let knobY = CGFloat(size) / 2 - knobSize / 2
    let knobPath = NSBezierPath(ovalIn: NSRect(x: knobX, y: knobY, width: knobSize, height: knobSize))
    knobPath.fill()

    // Volume icon (left)
    let volumeIconSize: CGFloat = 60
    let volumeIconX = sliderX - volumeIconSize - 20
    let volumeIconY = CGFloat(size) / 2 - volumeIconSize / 2
    let volumePath = NSBezierPath()
    volumePath.move(to: NSPoint(x: volumeIconX, y: volumeIconY + volumeIconSize * 0.3))
    volumePath.line(to: NSPoint(x: volumeIconX + volumeIconSize * 0.3, y: volumeIconY + volumeIconSize * 0.3))
    volumePath.line(to: NSPoint(x: volumeIconX + volumeIconSize * 0.6, y: volumeIconY))
    volumePath.line(to: NSPoint(x: volumeIconX + volumeIconSize * 0.6, y: volumeIconY + volumeIconSize))
    volumePath.line(to: NSPoint(x: volumeIconX + volumeIconSize * 0.3, y: volumeIconY + volumeIconSize * 0.7))
    volumePath.line(to: NSPoint(x: volumeIconX, y: volumeIconY + volumeIconSize * 0.7))
    volumePath.close()
    volumePath.fill()

    // Brightness icon (right)
    let brightnessIconSize: CGFloat = 60
    let brightnessIconX = sliderX + sliderWidth + 20
    let brightnessIconY = CGFloat(size) / 2 - brightnessIconSize / 2
    let brightnessPath = NSBezierPath()
    let center = NSPoint(x: brightnessIconX + brightnessIconSize / 2, y: brightnessIconY + brightnessIconSize / 2)
    let radius: CGFloat = brightnessIconSize * 0.3

    // Sun center
    let sunPath = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    sunPath.fill()

    // Sun rays
    for i in 0..<8 {
        let angle = CGFloat(i) * .pi / 4
        let innerRadius = radius * 1.3
        let outerRadius = radius * 1.8
        let startPoint = NSPoint(x: center.x + cos(angle) * innerRadius, y: center.y + sin(angle) * innerRadius)
        let endPoint = NSPoint(x: center.x + cos(angle) * outerRadius, y: center.y + sin(angle) * outerRadius)
        brightnessPath.move(to: startPoint)
        brightnessPath.line(to: endPoint)
    }
    brightnessPath.lineWidth = lineWidth
    brightnessPath.stroke()

    image.unlockFocus()
    return image
}

func saveIcon(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Icon saved to: \(path)")
    } catch {
        print("Failed to save icon: \(error)")
    }
}

// Generate icons at different sizes
let icon = createIcon()
if let icon = icon {
    let basePath = "ScrollControl/Assets.xcassets/AppIcon.appiconset"

    // Save at different sizes for Retina displays
    saveIcon(icon, to: "\(basePath)/AppIcon-128.png")
    saveIcon(icon, to: "\(basePath)/AppIcon-256.png")
    saveIcon(icon, to: "\(basePath)/AppIcon-512.png")

    print("App icons generated successfully!")
} else {
    print("Failed to create icon")
}
