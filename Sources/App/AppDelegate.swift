import AppKit
import Combine
import SwiftUI

@main
enum AppLayoutMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let model = AppModel()
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var observation: AnyCancellable?
    private var menuLanguage: InterfaceLanguage?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep one instance even when the executable is launched directly.
        let peers = NSRunningApplication.runningApplications(withBundleIdentifier: AppModel.bundleIdentifier)
        if peers.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }
        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
        observation = model.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.refreshAppearance() }
        }
        model.start()
        refreshAppearance()
        if !model.preferences.hasCompletedWelcome || model.storageError != nil {
            showSettings()
            if model.storageError == nil { model.completeWelcome() }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) { model.refreshLoginStatus() }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) { model.stop() }

    func menuWillOpen(_ menu: NSMenu) {
        model.refreshSources()
        menu.removeAllItems()
        let status = NSMenuItem(title: model.text(model.isPaused ? "status.paused" : "status.active"),
                                action: nil, keyEquivalent: "")
        menu.addItem(status)
        let source = NSMenuItem(title: model.currentSourceName, action: nil, keyEquivalent: "")
        menu.addItem(source)
        menu.addItem(.separator())
        addMenuItem(menu, key: model.isPaused ? "action.resume" : "action.pause", action: #selector(togglePause))
        addMenuItem(menu, key: "action.settings", action: #selector(showSettings), shortcut: ",")
        menu.addItem(.separator())
        addMenuItem(menu, key: "action.about", action: #selector(showAbout))
        addMenuItem(menu, key: "action.quit", action: #selector(quit), shortcut: "q")
    }

    private func addMenuItem(_ menu: NSMenu, key: String, action: Selector, shortcut: String = "") {
        let item = NSMenuItem(title: model.text(key), action: action, keyEquivalent: shortcut)
        item.target = self
        menu.addItem(item)
    }

    private func refreshAppearance() {
        let icon = NSImage(
            systemSymbolName: model.isPaused ? "pause.circle" : "keyboard",
            accessibilityDescription: "AppLayout"
        )
        icon?.isTemplate = true
        statusItem?.button?.image = icon
        statusItem?.button?.toolTip = "AppLayout — " + model.text(model.isPaused ? "status.paused" : "status.active")
        statusItem?.button?.setAccessibilityLabel("AppLayout")
        settingsWindow?.title = model.text("settings.title")
        if menuLanguage != model.preferences.language {
            configureMainMenu()
            menuLanguage = model.preferences.language
        }
    }

    private func configureMainMenu() {
        let main = NSMenu()
        func submenu(_ title: String) -> NSMenu {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let menu = NSMenu(title: title)
            item.submenu = menu
            main.addItem(item)
            return menu
        }
        let app = submenu("AppLayout")
        addMenuItem(app, key: "action.about", action: #selector(showAbout))
        app.addItem(.separator())
        addMenuItem(app, key: "action.settings", action: #selector(showSettings), shortcut: ",")
        app.addItem(.separator())
        addMenuItem(app, key: "action.quit", action: #selector(quit), shortcut: "q")
        let edit = submenu(model.text("menu.edit"))
        for (key, action, shortcut) in [
            ("action.undo", "undo:", "z"), ("action.redo", "redo:", "Z"),
            ("action.cut", "cut:", "x"), ("action.copy", "copy:", "c"),
            ("action.paste", "paste:", "v"), ("action.selectAll", "selectAll:", "a")
        ] {
            edit.addItem(NSMenuItem(title: model.text(key), action: Selector(action), keyEquivalent: shortcut))
        }
        let windows = submenu(model.text("menu.window"))
        windows.addItem(NSMenuItem(title: model.text("action.minimize"),
                                  action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windows.addItem(NSMenuItem(title: model.text("action.zoom"),
                                  action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        NSApp.windowsMenu = windows
        let help = submenu(model.text("menu.help"))
        addMenuItem(help, key: "action.help", action: #selector(showHelp))
        NSApp.helpMenu = help
        NSApp.mainMenu = main
    }

    @objc private func showHelp() {
        if let url = Bundle.main.url(forResource: "Help", withExtension: "html") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func togglePause() {
        if model.storageError != nil { showSettings() }
        else { model.setPaused(!model.isPaused) }
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 780, height: 650),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            window.title = model.text("settings.title")
            window.minSize = NSSize(width: 700, height: 560)
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(model: model))
            window.center()
            settingsWindow = window
        }
        model.refreshSources()
        model.refreshLoginStatus()
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "AppLayout",
            .applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            .credits: NSAttributedString(string: model.text("about.description") + "\nMIT · © 2026 LeshMesh")
        ])
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
