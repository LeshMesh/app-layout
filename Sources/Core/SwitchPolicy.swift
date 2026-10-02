import Foundation

public struct ApplicationIdentity: Equatable, Sendable {
    public var bundleIdentifier: String
    public var processIdentifier: Int32

    public init(bundleIdentifier: String, processIdentifier: Int32) {
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
    }
}

public struct SwitchRequest: Equatable, Sendable {
    public let generation: UInt64
    public let application: ApplicationIdentity
    public let inputSourceID: String
}

/// Event-driven decision layer; no keyboard hooks, timers, system APIs, or stored activity history.
public struct SwitchPolicy: Sendable {
    public let ownBundleIdentifier: String
    public private(set) var isPaused: Bool = false
    private var observedApplication: ApplicationIdentity?
    private var lastExternalApplication: ApplicationIdentity?
    private var generation: UInt64 = 0

    public init(ownBundleIdentifier: String) {
        self.ownBundleIdentifier = ownBundleIdentifier
    }

    public mutating func setPaused(_ paused: Bool) {
        isPaused = paused
        invalidatePending()
    }

    public mutating func invalidatePending() { generation &+= 1 }

    public mutating func activate(
        _ application: ApplicationIdentity?,
        rules: [AppRule],
        force: Bool = false
    ) -> SwitchRequest? {
        if !force && application == observedApplication { return nil }
        observedApplication = application
        invalidatePending()

        guard let application else {
            lastExternalApplication = nil
            return nil
        }
        // Opening our Settings must not reset a manual layout on return to the previous app.
        guard application.bundleIdentifier != ownBundleIdentifier else { return nil }
        let sameExternalApplication = lastExternalApplication == application
        lastExternalApplication = application
        guard !isPaused, force || !sameExternalApplication,
              let source = rules.first(where: {
                  $0.bundleIdentifier == application.bundleIdentifier
              })?.inputSourceID else { return nil }
        return SwitchRequest(
            generation: generation, application: application, inputSourceID: source
        )
    }

    public func isCurrent(_ request: SwitchRequest, frontmost: ApplicationIdentity?) -> Bool {
        !isPaused && request.generation == generation && frontmost == request.application
    }
}
