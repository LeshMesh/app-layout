# AppLayout

**An input source for every app.** A small, open-source menu bar utility for Apple Silicon Macs running macOS 26 or later.

[Русский](README.ru.md) · [Privacy](PRIVACY.md) · [Manual acceptance checks](docs/TESTING.md) · [Architecture](docs/ARCHITECTURE.md)

AppLayout applies the input source you choose when an application becomes active. For example, Chrome → Russian and PyCharm → ABC. It does not inspect your typing.

## Status

Version 1.0.0 adds a compact native settings interface with light/dark appearance, and launch at login enabled by default for new installations. Application switching was confirmed by the owner on an M1 Mac running macOS 26. The broader [acceptance checklist](docs/TESTING.md) records the remaining device-specific checks.

[Download 1.0.0](https://github.com/LeshMesh/app-layout/releases/tag/v1.0.0) · [Changelog](CHANGELOG.md)

Default builds are **ad-hoc signed for local use**, not Developer ID signed or notarized. No Apple Developer Program membership is needed for the local build instructions below. Public distribution signing is a later milestone.

## Behavior

- A rule is applied on application activation: click, Dock, or Cmd+Tab.
- Apps without a configured rule leave the input source unchanged.
- Manual changes remain until you leave the app and return.
- Switching windows within one process does not reapply a rule.
- Opening AppLayout settings and returning does not reset your manual choice.
- Choose any enabled, selectable keyboard input source, including input-method modes.
- Removed/disabled sources are marked unavailable; the current source is kept.
- Pause persists across restarts. Resuming or returning from sleep re-evaluates the current app.
- Rules edited in Settings take effect on the next activation from another app.
- English and Russian interface; launch at login defaults on and can be turned off.
- No telemetry, keyboard hooks, text inspection, background network access, or third-party runtime dependencies.

One rule applies to the entire application identified by Bundle ID. Browser tabs, URLs, IDE projects, remote desktops, virtual machines, and the pre-login screen are out of scope.

## Build on your Mac

Requirements: Apple Silicon, macOS 26+, Xcode 26+ with a macOS 26+ SDK.

1. Install and open Xcode once to finish its first-launch setup.
2. Clone this repository.
3. Build:

```sh
git clone https://github.com/LeshMesh/app-layout.git
cd app-layout
bash scripts/build.sh
```

The result is `build/local/Build/Products/Release/AppLayout.app`. Copy it into `/Applications` or `~/Applications` in Finder, then launch it. Install in a stable location before the first launch, which registers the login item.

Alternatively, open `AppLayout.xcodeproj`, select **AppLayout → My Mac**, and run. The project is configured for arm64 and local ad-hoc signing, with no development team.

If command-line tools point to a different Xcode, choose the installed Xcode under **Xcode → Settings → Locations → Command Line Tools**. The deployment target stays macOS 26.0 even when building with a newer Xcode.

## Configure

1. Open AppLayout from its keyboard icon in the menu bar.
2. Add Google Chrome and choose the exact Russian layout already enabled in macOS.
3. Add PyCharm and choose your preferred English source, such as ABC or U.S.
4. Add other apps, or leave them unconfigured.
5. In **System Settings → Keyboard → Text Input → Edit**, disable **Automatically switch to a document’s input source** for predictable rules. AppLayout does not change that preference.
6. Switch from another app into Chrome or PyCharm, and type to verify the actual source.

For an app outside the displayed folders, choose **Browse for an .app…**. Launch at login is enabled once on a fresh installation. You can turn it off in Settings; AppLayout never turns it back on automatically. macOS may require approval in Login Items. Upgrading from 0.1 preserves the existing macOS login setting; enable it once if desired.

## Development

```sh
swift test
python3 scripts/validate.py
bash scripts/build.sh
```

The Xcode project is checked in and opens without generators or package downloads. After adding or removing a Swift source/resource reference, run `python3 scripts/generate_project.py` and commit the generated project too. To redraw the original geometric icon, the optional `scripts/generate_icon.py` tool uses Pillow; normal builds use the checked-in PNGs and need no Pillow.

CI on `macos-26` runs tests, builds the normal app and an experimental sandbox variant, launches the native app for a smoke check, and renders six settings previews in Russian/English and light/dark appearances (including empty and paused states). Preview fixtures never start switching or register a login item. Run `python3 scripts/render_settings.py` on a Mac to reproduce them.

Release archives are the **ad-hoc, unnotarized** normal build from the passing CI run. Native screenshots and unit tests do not replace testing actual input in other apps.

## Sandbox and permissions

The default build uses Hardened Runtime, runs as the current user, and is not App Sandbox enabled. It requests no Accessibility, Input Monitoring, Screen Recording, Automation, or administrator permissions.

An experimental sandbox configuration is included:

```sh
bash scripts/build.sh sandbox
```

Its compilation is checked in CI, but system-wide input-source switching and application discovery must be tested interactively. Apple permits non-sandboxed Developer ID distribution; Mac App Store compatibility is not claimed. See [architecture](docs/ARCHITECTURE.md) for the decision and API references.

## Updates and removal

Updates are manual, from [GitHub Releases](https://github.com/LeshMesh/app-layout/releases). Quit AppLayout, replace the app in Applications, and reopen it; rules and preferences remain in Application Support. AppLayout never checks for a new version in the background.

To uninstall, turn off **Launch at login**, quit AppLayout, and move the app to Trash. Settings are stored in `~/Library/Application Support/AppLayout/settings.json`; remove this folder separately if you want to erase your rules. Experimental sandbox builds store data in their app container instead. Settings recovery preserves a backup alongside the original file.

## License

[MIT](LICENSE). Copyright © 2026 LeshMesh.
