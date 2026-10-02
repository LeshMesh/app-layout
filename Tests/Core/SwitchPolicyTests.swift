import Testing
@testable import AppLayoutCore

private let chrome = ApplicationIdentity(bundleIdentifier: "com.google.Chrome", processIdentifier: 10)
private let ide = ApplicationIdentity(bundleIdentifier: "com.jetbrains.pycharm", processIdentifier: 20)
private let utility = ApplicationIdentity(bundleIdentifier: "dev.leshmesh.AppLayout", processIdentifier: 30)
private let finder = ApplicationIdentity(bundleIdentifier: "com.apple.finder", processIdentifier: 40)
private let rules = [
    AppRule(bundleIdentifier: chrome.bundleIdentifier, displayName: "Chrome", inputSourceID: "ru"),
    AppRule(bundleIdentifier: ide.bundleIdentifier, displayName: "PyCharm", inputSourceID: "en")
]
private func policy() -> SwitchPolicy { SwitchPolicy(ownBundleIdentifier: utility.bundleIdentifier) }

@Test func appliesExactRuleOnActivation() {
    var state = policy()
    #expect(state.activate(chrome, rules: rules)?.inputSourceID == "ru")
    #expect(state.activate(ide, rules: rules)?.inputSourceID == "en")
}

@Test func unmatchedAndUnconfiguredAppsLeaveLayoutAlone() {
    var state = policy()
    #expect(state.activate(finder, rules: rules) == nil)
    #expect(state.activate(chrome, rules: [
        AppRule(bundleIdentifier: chrome.bundleIdentifier, displayName: "Chrome")
    ]) == nil)
}

@Test func duplicateActivationPreservesManualChoiceAndPendingRequest() throws {
    var state = policy()
    let request = try #require(state.activate(chrome, rules: rules))
    #expect(state.activate(chrome, rules: rules) == nil)
    #expect(state.isCurrent(request, frontmost: chrome))
}

@Test func rapidSwitchInvalidatesPreviousRequestEvenForUnconfiguredApp() throws {
    var state = policy()
    let stale = try #require(state.activate(chrome, rules: rules))
    #expect(state.activate(finder, rules: rules) == nil)
    #expect(!state.isCurrent(stale, frontmost: chrome))
}

@Test func requestCannotAffectDifferentFrontmostProcess() throws {
    var state = policy()
    let request = try #require(state.activate(chrome, rules: rules))
    #expect(!state.isCurrent(request, frontmost: ide))
    #expect(!state.isCurrent(request, frontmost: nil))
}

@Test func returningFromAnotherAppReappliesRule() {
    var state = policy()
    _ = state.activate(chrome, rules: rules)
    _ = state.activate(ide, rules: rules)
    #expect(state.activate(chrome, rules: rules)?.inputSourceID == "ru")
}

@Test func ownSettingsDoNotResetManualOverride() throws {
    var state = policy()
    let request = try #require(state.activate(chrome, rules: rules))
    #expect(state.activate(utility, rules: rules) == nil)
    #expect(!state.isCurrent(request, frontmost: chrome))
    #expect(state.activate(chrome, rules: rules) == nil)
    #expect(state.activate(ide, rules: rules)?.inputSourceID == "en")
}

@Test func pauseCancelsPendingAndResumeCanApplyCurrentRule() throws {
    var state = policy()
    let request = try #require(state.activate(chrome, rules: rules))
    state.setPaused(true)
    #expect(!state.isCurrent(request, frontmost: chrome))
    #expect(state.activate(ide, rules: rules) == nil)
    state.setPaused(false)
    #expect(state.activate(ide, rules: rules, force: true)?.inputSourceID == "en")
}

@Test func inputSourceChangeCanCancelPendingWithoutChangingSavedRule() throws {
    var state = policy()
    let request = try #require(state.activate(chrome, rules: rules))
    state.invalidatePending()
    #expect(!state.isCurrent(request, frontmost: chrome))
    #expect(state.activate(chrome, rules: rules) == nil)
    _ = state.activate(finder, rules: rules)
    #expect(state.activate(chrome, rules: rules)?.inputSourceID == "ru")
}

@Test func relaunchWithNewPIDCountsAsNewActivation() {
    var state = policy()
    _ = state.activate(chrome, rules: rules)
    let relaunched = ApplicationIdentity(bundleIdentifier: chrome.bundleIdentifier, processIdentifier: 99)
    #expect(state.activate(relaunched, rules: rules)?.inputSourceID == "ru")
}

@Test func unknownApplicationInvalidatesAndCountsAsLeaving() throws {
    var state = policy()
    let request = try #require(state.activate(chrome, rules: rules))
    #expect(state.activate(nil, rules: rules) == nil)
    #expect(!state.isCurrent(request, frontmost: chrome))
    #expect(state.activate(chrome, rules: rules)?.inputSourceID == "ru")
}

@Test func sourceIdentifiersAreNotReducedToLanguage() {
    var state = policy()
    let custom = [AppRule(bundleIdentifier: chrome.bundleIdentifier, displayName: "Chrome",
                          inputSourceID: "com.apple.keylayout.RussianWin")]
    #expect(state.activate(chrome, rules: custom)?.inputSourceID == "com.apple.keylayout.RussianWin")
}
