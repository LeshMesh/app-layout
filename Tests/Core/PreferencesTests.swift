import Foundation
import Testing
@testable import AppLayoutCore

private func temporaryRepository() throws -> PreferencesRepository {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return PreferencesRepository(fileURL: folder.appendingPathComponent("settings.json"))
}

@Test func newInstallationHasNoRulesAndInitializesLoginOnce() throws {
    let repository = try temporaryRepository()
    defer { try? FileManager.default.removeItem(at: repository.fileURL.deletingLastPathComponent()) }
    #expect(try repository.load() == Preferences())
    var fresh = try repository.load()
    let first = fresh.consumeLoginItemDefault()
    #expect(first)
    try repository.save(fresh)
    var reloaded = try repository.load()
    let second = reloaded.consumeLoginItemDefault()
    #expect(!second)
}

@Test func preferencesRoundTripWithUnicodeAndExactSources() throws {
    let repository = try temporaryRepository()
    defer { try? FileManager.default.removeItem(at: repository.fileURL.deletingLastPathComponent()) }
    var preferences = Preferences()
    preferences.language = .ru
    preferences.isPaused = true
    preferences.rules = [
        AppRule(bundleIdentifier: "com.google.Chrome", displayName: "Браузер",
                inputSourceID: "com.apple.keylayout.RussianWin")
    ]
    try repository.save(preferences)
    #expect(try repository.load() == preferences)
}

@Test func malformedSettingsArePreservedForRecovery() throws {
    let repository = try temporaryRepository()
    defer { try? FileManager.default.removeItem(at: repository.fileURL.deletingLastPathComponent()) }
    let original = Data("not JSON".utf8)
    try original.write(to: repository.fileURL)
    #expect(throws: (any Error).self) { try repository.load() }
    #expect(try Data(contentsOf: repository.fileURL) == original)
    let savedBackup = try repository.backUpAndReset()
    let backup = try #require(savedBackup)
    #expect(try Data(contentsOf: backup) == original)
    let reset = try repository.load()
    #expect(reset.rules.isEmpty)
    #expect(reset.hasInitializedLoginItem)
}

@Test func futureVersionIsRejectedRatherThanOverwritten() throws {
    let repository = try temporaryRepository()
    defer { try? FileManager.default.removeItem(at: repository.fileURL.deletingLastPathComponent()) }
    var future = Preferences()
    future.schemaVersion = 99
    let bytes = try JSONEncoder().encode(future)
    try bytes.write(to: repository.fileURL)
    #expect(throws: PreferencesError.unsupportedVersion(99)) { try repository.load() }
    #expect(try Data(contentsOf: repository.fileURL) == bytes)
}

@Test func duplicateRulesAndEmptySourcesAreRejected() throws {
    var preferences = Preferences()
    let rule = AppRule(bundleIdentifier: "app", displayName: "App", inputSourceID: "en")
    preferences.rules = [rule, rule]
    #expect(throws: PreferencesError.invalidRules) { try preferences.validated() }
    preferences.rules = [AppRule(bundleIdentifier: "app", displayName: "App", inputSourceID: "")]
    #expect(throws: PreferencesError.invalidRules) { try preferences.validated() }
}

@Test func upgradingVersion01PreservesRulesAndExistingLoginSetting() throws {
    let bytes = Data("""
    {"schemaVersion":1,"language":"ru","isPaused":true,"hasCompletedWelcome":true,
     "rules":[{"bundleIdentifier":"com.google.Chrome","displayName":"Chrome","inputSourceID":"ru"}]}
    """.utf8)
    var migrated = try JSONDecoder().decode(Preferences.self, from: bytes)
    #expect(migrated.isPaused)
    #expect(migrated.language == .ru)
    #expect(migrated.rules.first?.inputSourceID == "ru")
    let shouldRegister = migrated.consumeLoginItemDefault()
    #expect(!shouldRegister)
}

@Test func incompleteOldFirstLaunchStillReceivesNewDefault() throws {
    let bytes = Data("""
    {"schemaVersion":1,"language":"en","isPaused":false,"hasCompletedWelcome":false,"rules":[]}
    """.utf8)
    var preferences = try JSONDecoder().decode(Preferences.self, from: bytes)
    let shouldRegister = preferences.consumeLoginItemDefault()
    #expect(shouldRegister)
}

@Test func recoveryDoesNotReenablePreviouslyDisabledLoginItem() throws {
    let repository = try temporaryRepository()
    defer { try? FileManager.default.removeItem(at: repository.fileURL.deletingLastPathComponent()) }
    var preferences = Preferences()
    _ = preferences.consumeLoginItemDefault()
    try repository.save(preferences)
    try repository.backUpAndReset()
    var recovered = try repository.load()
    let shouldRegister = recovered.consumeLoginItemDefault()
    #expect(!shouldRegister)
}
