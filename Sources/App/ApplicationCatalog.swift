import AppKit

struct ApplicationCandidate: Identifiable, Sendable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let name: String
    let url: URL
}

enum ApplicationCatalog {
    static func candidate(at url: URL) -> ApplicationCandidate? {
        guard url.pathExtension.lowercased() == "app",
              let bundle = Bundle(url: url),
              let identifier = bundle.bundleIdentifier,
              bundle.object(forInfoDictionaryKey: "LSBackgroundOnly") as? Bool != true else { return nil }
        let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
        return ApplicationCandidate(bundleIdentifier: identifier, name: name, url: url)
    }

    // Local directories only. Apps in other locations can be added through the file picker.
    static func installedApplications() -> [ApplicationCandidate] {
        let directories = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        return directories.flatMap { directory in
            (try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            )) ?? []
        }.compactMap(candidate)
    }

    @MainActor
    static func runningApplications() -> [ApplicationCandidate] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard app.activationPolicy == .regular,
                  let identifier = app.bundleIdentifier,
                  let url = app.bundleURL else { return nil }
            return ApplicationCandidate(
                bundleIdentifier: identifier, name: app.localizedName ?? identifier, url: url
            )
        }
    }
}
