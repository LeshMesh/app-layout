# Changelog

## 1.0.0 — 2026-10-03

- Redesigned native settings: compact application rows, system light/dark appearance, grouped controls, and contextual help.
- Enabled launch at login once for fresh installations through SMAppService; manual opt-out is respected across restarts.
- Preserved existing 0.1 rules and macOS login-item choices on upgrade.
- Localized SwiftUI system controls to the chosen interface language; added Command-W to close Settings and Command-N to add an application.
- Added migration/recovery tests and native UI preview artifacts to macOS CI.
- Kept the user-tested activation engine, offline operation, and zero third-party runtime dependencies.

Apple Silicon, macOS 26+. Ad-hoc builds; Developer ID signing and notarization remain deferred.

## 0.1.0

- Initial menu bar app with per-application input sources, persistent rules, pause, RU/EN interface, local application discovery and optional launch at login.
