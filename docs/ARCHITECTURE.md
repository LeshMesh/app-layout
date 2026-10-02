# Architecture and boundaries

## Platform

Native Swift 6, AppKit lifecycle and menu bar, SwiftUI settings. Deployment target macOS 26.0; arm64 only. No external packages or embedded web runtime.

The checked-in Xcode project compiles Sources/Core together with Sources/App. The standalone Swift package builds the same core source for unit testing; production does not depend on a separately downloaded package.

## Activation flow

1. NSWorkspace's own notification center delivers application activation.
2. SwitchPolicy compares the process/bundle identity and exact per-app rule.
3. A single 40 ms task lets activation settle. Its generation token is invalidated by another activation, pause, session changes, rule changes, or a changed input source.
4. Before selecting, the app rechecks the frontmost process and source. A stale request never changes the layout for another process.
5. InputSourceService enumerates enabled/selectable keyboard sources and calls TISSelectInputSource for the exact ID.
6. An OS error is shown locally. No retry loop attempts to override a manual or system choice.

Input-source notifications update displayed state and cancel pending work; they never trigger rule enforcement. A successful TIS return is not treated as proof of actual typing behavior in a foreign app. The live acceptance checklist is necessary.

There is no guarantee that an immediately typed first character following Cmd+Tab precedes/completes after the asynchronous OS switch. The app never buffers or suppresses keystrokes to achieve that.

## App identity and utility focus

Bundle ID persists across renames and normal app updates. PID distinguishes a new process or separately running instance. Rules themselves are shared by bundle ID. Apps without bundle IDs have no rule; their activation invalidates pending work.

The last external app is remembered in memory so opening our own settings and returning does not reset a manual choice. Another external app, including one without a rule, counts as leaving. The menu bar menu normally does not activate the utility.

## Storage and resources

PreferencesRepository stores a versioned JSON document with atomic writes. Malformed settings and future versions pause automation instead of being overwritten. User-confirmed recovery copies the prior bytes to a backup first. No activity history or text is stored.

Exact enabled source IDs are persisted, including selectable IME modes. Sources that cease to be enabled remain in the rule and are visibly marked unavailable. No source is installed, enabled, or removed by AppLayout.

## Login item

SMAppService.mainApp is the only autostart mechanism. No LaunchAgent plist, helper daemon, root process, or administrator prompt. The UI reads the OS registration state and handles requiresApproval. It does not re-register automatically after the user disables it.

## Sandbox decision

The main local build enables Hardened Runtime and disables App Sandbox. An explicit experimental sandbox build is included with read-only access to user-selected files and no network entitlements.

Switching an input source system-wide from a sandboxed process needs interactive verification in focused text clients. Building the sandbox variant successfully does not establish that this works correctly. The sandbox build should not be promoted to the default until it passes docs/TESTING.md. A failure is not a reason to add Accessibility or keyboard hooks without revisiting scope.

Apple permits non-sandboxed notarized distribution outside the App Store. Mac App Store acceptance and complete HIG compliance are not claimed before live accessibility/UI review and distribution checks.

## Apple references

- [NSWorkspace activation notification](https://developer.apple.com/documentation/appkit/nsworkspace/didactivateapplicationnotification)
- [Text input-source identifiers](https://developer.apple.com/documentation/appkit/nstextinputcontext/keyboardinputsources)
- [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Preparing for distribution: Sandbox and Hardened Runtime](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution)
- [Notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)

TIS declarations come from the public Carbon/HIToolbox SDK headers. Their SDK availability and compiler diagnostics are checked by the native build. The old name Carbon does not justify introducing unrelated deprecated Carbon UI APIs.
