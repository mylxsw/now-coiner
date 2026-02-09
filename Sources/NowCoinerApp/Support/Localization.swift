import Foundation
import NowCoinerCore

enum L10n {
    private static let languageKey = "nowcoiner.app.language"

    static func setLanguage(_ value: AppLanguage) {
        UserDefaults.standard.set(value.rawValue, forKey: languageKey)
    }

    static func tr(_ key: String) -> String {
        let bundle = localizedBundle()
        return NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
    }

    static func tr(_ key: String, _ arguments: CVarArg...) -> String {
        let format = tr(key)
        return String(format: format, locale: formatLocale(), arguments: arguments)
    }

    private static func localizedBundle() -> Bundle {
        let language = currentLanguage()
        let targetCode: String?
        switch language {
        case .followSystem:
            targetCode = nil
        case .zhHans:
            targetCode = "zh-Hans"
        case .en:
            targetCode = "en"
        }

        guard let targetCode,
              let bundle = bundle(forLanguageCode: targetCode) else {
            return Bundle.module
        }
        return bundle
    }

    private static func formatLocale() -> Locale {
        let language = currentLanguage()
        switch language {
        case .followSystem:
            return Locale.current
        case .zhHans:
            return Locale(identifier: "zh-Hans")
        case .en:
            return Locale(identifier: "en")
        }
    }

    private static func currentLanguage() -> AppLanguage {
        guard let raw = UserDefaults.standard.string(forKey: languageKey),
              let value = AppLanguage(rawValue: raw) else {
            return .followSystem
        }
        return value
    }

    private static func bundle(forLanguageCode code: String) -> Bundle? {
        let normalizedTarget = normalizeLanguageCode(code)
        let available = Bundle.module.localizations

        if let matched = available.first(where: { normalizeLanguageCode($0) == normalizedTarget }),
           let path = Bundle.module.path(forResource: matched, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        if let path = Bundle.module.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        return nil
    }

    private static func normalizeLanguageCode(_ code: String) -> String {
        code.replacingOccurrences(of: "_", with: "-").lowercased()
    }
}
