import Foundation

public enum InterfaceLanguage: String, Codable, CaseIterable, Sendable {
    case system, en, ru
}

public struct AppRule: Codable, Equatable, Identifiable, Sendable {
    public var id: String { bundleIdentifier }
    public var bundleIdentifier: String
    public var displayName: String
    public var inputSourceID: String?

    public init(bundleIdentifier: String, displayName: String, inputSourceID: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.inputSourceID = inputSourceID
    }
}

public struct Preferences: Codable, Equatable, Sendable {
    public var schemaVersion: Int = 1
    public var language: InterfaceLanguage = .system
    public var isPaused: Bool = false
    public var hasCompletedWelcome: Bool = false
    public var rules: [AppRule] = []

    public init() {}

    public func validated() throws -> Preferences {
        guard schemaVersion == 1 else { throw PreferencesError.unsupportedVersion(schemaVersion) }
        var identifiers = Set<String>()
        for rule in rules {
            guard !rule.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !rule.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  rule.inputSourceID != "",
                  identifiers.insert(rule.bundleIdentifier).inserted else {
                throw PreferencesError.invalidRules
            }
        }
        return self
    }
}

public enum PreferencesError: Error, Equatable {
    case unsupportedVersion(Int)
    case invalidRules
}

/// Writes only the app's own settings. Corrupt or future-version files are never silently replaced.
public struct PreferencesRepository: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load() throws -> Preferences {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return Preferences() }
        return try JSONDecoder().decode(Preferences.self, from: Data(contentsOf: fileURL)).validated()
    }

    public func save(_ preferences: Preferences) throws {
        let validated = try preferences.validated()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(validated).write(to: fileURL, options: .atomic)
    }

    /// Used only after the user confirms recovery in Settings.
    @discardableResult
    public func backUpAndReset() throws -> URL? {
        var backup: URL?
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let destination = fileURL.appendingPathExtension("backup-\(UUID().uuidString)")
            try FileManager.default.copyItem(at: fileURL, to: destination)
            backup = destination
        }
        try save(Preferences())
        return backup
    }
}
