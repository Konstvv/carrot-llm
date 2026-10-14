import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: set-desktop-icon.swift IMAGE.png FILE\n", stderr)
    exit(2)
}

let iconPath = CommandLine.arguments[1]
let targetPath = CommandLine.arguments[2]
guard let icon = NSImage(contentsOfFile: iconPath) else {
    fputs("Could not read icon image: \(iconPath)\n", stderr)
    exit(1)
}
guard NSWorkspace.shared.setIcon(icon, forFile: targetPath, options: []) else {
    fputs("Finder could not set the icon for: \(targetPath)\n", stderr)
    exit(1)
}
