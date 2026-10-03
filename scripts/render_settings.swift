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
            let model = AppModel()
            model.preparePreview(language: language, empty: empty, paused: paused)
            try render(SettingsView(model: model), name: name, appearance: appearance,
                       size: NSSize(width: 700, height: 700), destination: destination)
        }
        let candidates = [
            ("com.google.Chrome", "Google Chrome"),
            ("com.jetbrains.pycharm", "PyCharm"),
            ("com.apple.Safari", "Safari"),
            ("com.apple.TextEdit", "TextEdit")
        ].map { id, name in
            ApplicationCandidate(bundleIdentifier: id, name: name,
                                 url: URL(fileURLWithPath: "/Applications/\(name).app"))
        }
        for language in [InterfaceLanguage.en, .ru] {
            for (theme, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                let model = AppModel()
                model.preparePreview(language: language, empty: true)
                let view = ApplicationPickerView(model: model, applications: candidates,
                                                 selection: ["com.google.Chrome", "com.jetbrains.pycharm"])
                    .environment(\.locale, model.interfaceLocale)
                try render(view, name: "picker-\(language.rawValue)-\(theme)", appearance: appearance,
                           size: NSSize(width: 570, height: 500), destination: destination)
            }
        }
    }

    @MainActor private static func render<V: View>(
        _ view: V, name: String, appearance: NSAppearance.Name, size: NSSize, destination: URL
    ) throws {
        let app = NSApplication.shared
        app.appearance = NSAppearance(named: appearance)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = app.appearance
        let hosting = NSHostingView(rootView: view)
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
