# Acceptance testing on a Mac

Record the Mac model, exact macOS version, Xcode version, app commit, Chrome/PyCharm versions, exact input-source names, and whether App Sandbox is enabled. Do not post passwords, text contents, or unrelated private app names.

**User verification:** the owner reported correct application switching on an M1 Mac running macOS 26 before the 1.0 UI update. Exact OS patch, application versions and the individual cases below were not recorded; the checkboxes therefore remain open. The switching engine is unchanged in 1.0.

CI checks are separate: they compile and launch the native app, run core tests, and render settings for visual inspection. They do not type into Chrome/PyCharm, perform a real login, or establish VoiceOver behavior.

## Automated

- `swift test`: activation rule decisions, duplicate events, stale work, manual-change cancellation, unknown apps, utility settings, restart PIDs, pause/resume, exact source IDs, storage round trips and recovery, one-time login initialization and migration from 0.1.
- `python3 scripts/validate.py`: property lists, matching localization keys, referenced local assets.
- GitHub Actions: compile arm64 with a macOS 26 SDK or later, verify ad-hoc signature, build normal and sandbox variants, package the normal build for local testing.
- Regenerate the Xcode project and assert that the checked-in version matches.

## Preparation

- Build locally and put one copy of AppLayout in Applications.
- Enable your Russian source and ABC/U.S. in macOS.
- Disable macOS's document-specific source restoration.
- Quit other automatic layout tools.
- Set Chrome → your Russian source, PyCharm → your English source.
- Keep TextEdit or Finder without a rule.
- Use a fresh macOS account to check that no TCC input/screen/Accessibility permissions are needed.

## Switching matrix

- [ ] Click Chrome and type in an empty field: Russian characters appear.
- [ ] Cmd+Tab to PyCharm and type in a scratch file: English characters appear.
- [ ] Activate each via Dock; repeat after launching an app that was not running.
- [ ] In PyCharm manually choose Russian and type: it remains Russian.
- [ ] Change focus between editor and terminal, and between windows of the same PyCharm process: no enforced reset.
- [ ] Leave for Chrome, then return to PyCharm: English is restored.
- [ ] Open AppLayout's menu and settings, then return: manual choice remains.
- [ ] Switch to the app without a rule: current source remains.
- [ ] Rapidly alternate apps 30 times: no late switch changes the source for the wrong app.
- [ ] Type immediately after switching; record any wrong-layout first character and the timing. No claim of zero-latency switching.
- [ ] Check a full-screen browser/IDE, Spaces, Stage Manager, and a second display if available.
- [ ] Add a third enabled source and test an app rule for it.
- [ ] If using an IME, test the exact selectable mode and actual composed text.
- [ ] Remove/disable an assigned source: current input stays usable and Settings marks the rule unavailable.
- [ ] Re-enable the source: next activation applies its existing rule.
- [ ] Edit/remove a rule while paused and active; it takes effect on the next external-app activation.
- [ ] Check secure text fields with non-sensitive test data; respect any OS restriction, never defeat it.

## Lifecycle and privacy

- [ ] Pause prevents switching. Quit and reopen: pause is retained.
- [ ] Resume evaluates the current app on the next activation when Settings is focused.
- [ ] Sleep/wake and switch user away/back: no stale request executes in an inactive session.
- [ ] Restart configured apps: their rules still work.
- [ ] A fresh installation enables Launch at login; approve in macOS if requested. Quit/reopen and log out/in to verify.
- [ ] Turn Launch at login off, quit/reopen: it stays off.
- [ ] Upgrade 0.1 with the item enabled and disabled: each system choice and existing rules are preserved.
- [ ] Settings recovery does not enable a previously disabled login item.
- [ ] Disable the item in System Settings: the app does not re-enable it.
- [ ] Close Settings: the menu item and automation continue. Quit: the process exits.
- [ ] Uninstall after disabling login item: no background helper remains.
- [ ] Observe the AppLayout process with Activity Monitor/Instruments: idle CPU is near zero, no recurring timer work.
- [ ] Observe network activity: AppLayout makes no connections during ordinary use.
- [ ] Corrupt a disposable copy of settings: automation stops and recovery preserves a backup.

## Interface and accessibility

- [ ] First launch shows Settings; subsequent login launch is unobtrusive.
- [ ] Russian, English, and system-language selection localize labels and menus.
- [ ] Test narrow window size, long app/source names, light/dark appearances, Increase Contrast and Reduce Transparency.
- [ ] Navigate controls without a mouse; check Tab order, Escape/Return in picker, and standard Copy/Paste.
- [ ] VoiceOver announces the menu bar button, rules, source pickers, remove buttons, pause and login controls.
- [ ] App settings are reachable through the menu and by reopening AppLayout in Finder.
- [ ] Source code link opens only when clicked; local help opens offline.

## Sandbox experiment

Build `bash scripts/build.sh sandbox`, quit the normal app, and run only that variant. Repeat the switching matrix, including already-focused input fields in Chrome and PyCharm. Verify application discovery and file-picker access. Record actual typed output, not just the menu bar source icon. Sandbox and normal preferences live in different locations; configure rules in each build.

If sandbox switching fails, keep the normal build and report the exact context. Do not claim App Store compatibility or add new permissions as an unreviewed workaround.
