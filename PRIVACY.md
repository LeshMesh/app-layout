# Privacy

AppLayout processes data locally on your Mac.

## What it uses

- The bundle identifier and process identifier of the active application, transiently, to select a rule.
- Enabled keyboard input-source identifiers and localized names.
- App names, bundle identifiers, and icons to show the application picker.
- Your explicit application rules, pause state, interface language, and one-time setup markers, saved in the app's settings file.

No application-usage history is recorded. The app does not read keystrokes, text fields, clipboard contents, browser URLs, document names, or screen content.

## Network

The app contains no network client, analytics SDK, update checker, account system, ads, remote fonts, or telemetry. The Source code link opens GitHub in your browser only when selected. Local Help is bundled with the app.

The development workflow downloads source and runs GitHub Actions. macOS may separately perform its normal operating-system security checks. These are not AppLayout background requests.

## Permissions

The app uses public NSWorkspace and Text Input Source Services APIs. It does not request Accessibility, Input Monitoring, Screen Recording, Automation, Full Disk Access, or administrator access. Launch at login uses Apple's Service Management API. A fresh installation registers once by default; you can disable it in AppLayout or macOS. Existing installations preserve the system's setting on upgrade.

## Stored data and recovery

Normal builds: `~/Library/Application Support/AppLayout/settings.json`.
Sandbox experiments: the corresponding Application Support directory in the app container.

Rules are stored by bundle ID and exact input-source ID, not by full app paths. The file is written atomically. Invalid or newer-schema files are left untouched and automation is paused. Confirmed recovery copies the previous file to a backup before resetting it.

## Diagnostics

Errors are shown locally. No logs or crash reports are uploaded by AppLayout. If you report a problem on GitHub, share only information you choose to disclose. Apple's own diagnostics settings are independent of this app.

## Русский

Настройки и правила остаются на Mac. Приложение не читает вводимый текст, буфер обмена, адреса сайтов и содержимое экрана; не сохраняет историю использования приложений. Аналитики, учётных записей, автоматической проверки обновлений и фоновых сетевых запросов нет. Ссылка на исходный код открывается только по нажатию. При новой установке автозапуск включается однократно через штатный механизм macOS. Его можно отключить в приложении или системных настройках; повторно автоматически он не включается.
