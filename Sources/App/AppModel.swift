import AppKit
import Carbon
import Combine
import ServiceManagement

@MainActor
final class AppModel: NSObject, ObservableObject {
    static let bundleIdentifier = "dev.leshmesh.AppLayout"

    @Published private(set) var preferences = Preferences()
    @Published private(set) var inputSources: [InputSourceOption] = []
    @Published private(set) var currentSourceID: String?
    @Published private(set) var activeApplicationName = ""
    @Published private(set) var issueKey: String?
    @Published private(set) var issueDetail = ""
    @Published private(set) var storageError: String?
    @Published private(set) var loginStatus = SMAppService.mainApp.status
    @Published private(set) var isUpdatingLogin = false

    private let sources = InputSourceService()
    private let repository: PreferencesRepository
    private var policy = SwitchPolicy(ownBundleIdentifier: AppModel.bundleIdentifier)
    private var pendingSwitch: Task<Void, Never>?
    private var sessionAvailable = true
    private var started = false

    var isPaused: Bool { preferences.isPaused || storageError != nil }
    var currentSourceName: String {
        inputSources.first(where: { $0.id == currentSourceID })?.name ?? text("source.unknown")
    }
    var launchAtLogin: Bool { loginStatus == .enabled || loginStatus == .requiresApproval }

    override init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        repository = PreferencesRepository(
            fileURL: support.appendingPathComponent("AppLayout/settings.json")
        )
        super.init()
        do { preferences = try repository.load() }
        catch { storageError = String(describing: error) }
        policy.setPaused(isPaused)
    }

    func text(_ key: String) -> String { L10n.string(key, language: preferences.language) }

    func start() {
        guard !started else { return }
        started = true
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(applicationActivated(_:)),
                              name: NSWorkspace.didActivateApplicationNotification, object: nil)
        workspace.addObserver(self, selector: #selector(sessionResumed),
                              name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(sessionSuspended),
                              name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(sessionSuspended),
                              name: NSWorkspace.willSleepNotification, object: nil)
        workspace.addObserver(self, selector: #selector(sessionResumed),
                              name: NSWorkspace.didWakeNotification, object: nil)
        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(self, selector: #selector(inputSourceChanged),
                                name: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
                                object: nil)
        distributed.addObserver(self, selector: #selector(enabledSourcesChanged),
                                name: Notification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
                                object: nil)
        refreshSources()
        handleActivation(NSWorkspace.shared.frontmostApplication, force: true)
    }

    func stop() {
        pendingSwitch?.cancel()
        policy.invalidatePending()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
        started = false
    }

    func completeWelcome() {
        var next = preferences
        next.hasCompletedWelcome = true
        commit(next)
    }

    func setPaused(_ paused: Bool) {
        var next = preferences
        next.isPaused = paused
        guard commit(next) else { return }
        pendingSwitch?.cancel()
        policy.setPaused(paused)
        issueKey = nil
        if !paused { handleActivation(NSWorkspace.shared.frontmostApplication, force: true) }
    }

    func setLanguage(_ language: InterfaceLanguage) {
        var next = preferences
        next.language = language
        commit(next)
    }

    func addApplication(_ app: ApplicationCandidate) {
        guard app.bundleIdentifier != Self.bundleIdentifier,
              !preferences.rules.contains(where: { $0.id == app.id }) else { return }
        var next = preferences
        next.rules.append(AppRule(bundleIdentifier: app.bundleIdentifier, displayName: app.name))
        next.rules.sort { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        commit(next)
    }

    func setInputSource(_ sourceID: String?, for bundleID: String) {
        var next = preferences
        guard let index = next.rules.firstIndex(where: { $0.id == bundleID }) else { return }
        next.rules[index].inputSourceID = sourceID
        if commit(next) {
            // Editing a rule is not an activation event.
            pendingSwitch?.cancel()
            policy.invalidatePending()
            issueKey = nil
        }
    }

    func removeRule(_ bundleID: String) {
        var next = preferences
        next.rules.removeAll { $0.id == bundleID }
        if commit(next) {
            pendingSwitch?.cancel()
            policy.invalidatePending()
            issueKey = nil
        }
    }

    func recoverSettings() {
        do {
            try repository.backUpAndReset()
            preferences = try repository.load()
            storageError = nil
            issueKey = nil
            pendingSwitch?.cancel()
            policy = SwitchPolicy(ownBundleIdentifier: Self.bundleIdentifier)
            handleActivation(NSWorkspace.shared.frontmostApplication, force: true)
        } catch {
            storageError = String(describing: error)
        }
    }

    func refreshLoginStatus() { loginStatus = SMAppService.mainApp.status }

    func setLaunchAtLogin(_ enabled: Bool) {
        guard !isUpdatingLogin else { return }
        isUpdatingLogin = true
        Task { @MainActor in
            defer {
                self.isUpdatingLogin = false
                self.refreshLoginStatus()
            }
            do {
                if enabled { try SMAppService.mainApp.register() }
                else { try await SMAppService.mainApp.unregister() }
                self.issueKey = nil
            } catch {
                self.issueKey = "error.login"
                self.issueDetail = error.localizedDescription
            }
        }
    }

    func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }

    @discardableResult
    private func commit(_ next: Preferences) -> Bool {
        guard storageError == nil else { return false }
        do {
            try repository.save(next)
            preferences = next
            return true
        } catch {
            storageError = error.localizedDescription
            pendingSwitch?.cancel()
            policy.setPaused(true)
            return false
        }
    }

    @objc private func applicationActivated(_ notification: Notification) {
        guard sessionAvailable else { return }
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        handleActivation(app)
    }

    @objc private func sessionSuspended() {
        sessionAvailable = false
        pendingSwitch?.cancel()
        policy.invalidatePending()
    }

    @objc private func sessionResumed() {
        sessionAvailable = true
        refreshSources()
        handleActivation(NSWorkspace.shared.frontmostApplication, force: true)
    }

    @objc private func inputSourceChanged() {
        let updated = sources.currentID()
        // A source change before our deferred switch may be the user's manual choice.
        // Never compete with it, and never enforce a saved rule on source-change notifications.
        if updated != currentSourceID {
            pendingSwitch?.cancel()
            policy.invalidatePending()
        }
        currentSourceID = updated
    }

    @objc private func enabledSourcesChanged() {
        pendingSwitch?.cancel()
        policy.invalidatePending()
        refreshSources()
    }

    func refreshSources() {
        inputSources = sources.options()
        currentSourceID = sources.currentID()
    }

    private func identity(of app: NSRunningApplication?) -> ApplicationIdentity? {
        guard let app, let identifier = app.bundleIdentifier else { return nil }
        return ApplicationIdentity(bundleIdentifier: identifier, processIdentifier: app.processIdentifier)
    }

    private func handleActivation(_ app: NSRunningApplication?, force: Bool = false) {
        let identity = identity(of: app)
        if identity?.bundleIdentifier != Self.bundleIdentifier {
            activeApplicationName = app?.localizedName ?? ""
        }
        // A duplicate event must not cancel the original pending activation.
        guard let request = policy.activate(identity, rules: preferences.rules, force: force) else { return }
        pendingSwitch?.cancel()
        issueKey = nil
        let originalSource = sources.currentID()
        currentSourceID = originalSource
        guard originalSource != request.inputSourceID else { return }

        pendingSwitch = Task { @MainActor [weak self] in
            // One bounded activation delay; no polling or retry loop.
            do { try await Task.sleep(for: .milliseconds(40)) }
            catch { return }
            guard let self, !Task.isCancelled, self.sessionAvailable,
                  self.policy.isCurrent(request, frontmost: self.identity(of: NSWorkspace.shared.frontmostApplication)),
                  self.sources.currentID() == originalSource else { return }
            self.pendingSwitch = nil
            switch self.sources.select(id: request.inputSourceID) {
            case .selected: break
            case .unavailable:
                self.issueKey = "error.sourceUnavailable"
                self.issueDetail = request.inputSourceID
            case .failed(let status):
                self.issueKey = "error.switch"
                self.issueDetail = String(status)
            }
            self.currentSourceID = self.sources.currentID()
        }
    }
}
