import AppKit
import SwiftUI

/// Compiled separately with APP_LAYOUT_PREVIEW. Never starts the switching service or login item.
@main
enum RenderSettings {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let scenarios: [(String, InterfaceLanguage, NSAppearance.Name, Bool, Bool)] = [
            ("en-light", .en, .aqua, false, false),
            ("ru-light", .ru, .aqua, false, false),
            ("en-dark", .en, .darkAqua, false, false),
            ("ru-dark", .ru, .darkAqua, false, false),
            ("ru-empty", .ru, .aqua, true, false),
            ("en-paused", .en, .darkAqua, false, true)
        ]
        for (name, language, appearance, empty, paused) in scenarios {
            app.appearance = NSAppearance(named: appearance)
            let model = AppModel()
            model.preparePreview(language: language, empty: empty, paused: paused)
            let size = NSSize(width: 700, height: 700)
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.appearance = app.appearance
            let hosting = NSHostingView(rootView: SettingsView(model: model))
            window.contentView = hosting
            window.setContentSize(size)
            window.makeKeyAndOrderFront(nil)
            app.activate()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.6))
            hosting.layoutSubtreeIfNeeded()
            hosting.displayIfNeeded()
            guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
                throw CocoaError(.fileWriteUnknown)
            }
            hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
            guard let png = bitmap.representation(using: .png, properties: [:]) else {
                throw CocoaError(.fileWriteUnknown)
            }
            try png.write(to: destination.appendingPathComponent(name + ".png"))
            print("Rendered \(name): \(bitmap.pixelsWide) x \(bitmap.pixelsHigh)")
            window.close()
        }
    }
}
