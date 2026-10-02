import Foundation

enum L10n {
    static func string(_ key: String, language: InterfaceLanguage) -> String {
        let code: String
        switch language {
        case .system:
            code = Bundle.preferredLocalizations(
                from: ["en", "ru"], forPreferences: Locale.preferredLanguages
            ).first ?? "en"
        case .en: code = "en"
        case .ru: code = "ru"
        }
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
