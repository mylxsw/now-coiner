import Foundation
import NowCoinerCore

enum L10n {
    private static let languageKey = "nowcoiner.app.language"
    private static let missingToken = "__NOWCOINER_L10N_MISSING__"

    static func setLanguage(_ value: AppLanguage) {
        UserDefaults.standard.set(value.rawValue, forKey: languageKey)
    }

    static func tr(_ key: String) -> String {
        let bundles = localizedBundles()
        for bundle in bundles {
            let value = NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: missingToken, comment: "")
            if value != missingToken {
                return value
            }
        }
        return key
    }

    static func tr(_ key: String, _ arguments: CVarArg...) -> String {
        let format = tr(key)
        return String(format: format, locale: formatLocale(), arguments: arguments)
    }

    private static func localizedBundles() -> [Bundle] {
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

        let bases = baseBundles()
        if let targetCode {
            let localized = bases.compactMap { bundle(forLanguageCode: targetCode, in: $0) }
            if !localized.isEmpty {
                return dedupeBundles(localized + bases)
            }
        }
        return bases
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

    private static func baseBundles() -> [Bundle] {
        #if SWIFT_PACKAGE
        return dedupeBundles([Bundle.main, Bundle.module])
        #else
        return dedupeBundles([Bundle.main])
        #endif
    }

    private static func bundle(forLanguageCode code: String, in base: Bundle) -> Bundle? {
        let normalizedTarget = normalizeLanguageCode(code)
        let available = base.localizations

        if let matched = available.first(where: { normalizeLanguageCode($0) == normalizedTarget }),
           let path = base.path(forResource: matched, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        if let path = base.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        return nil
    }

    private static func dedupeBundles(_ bundles: [Bundle]) -> [Bundle] {
        var seen: Set<String> = []
        var result: [Bundle] = []
        for bundle in bundles {
            if seen.insert(bundle.bundlePath).inserted {
                result.append(bundle)
            }
        }
        return result
    }

    private static func normalizeLanguageCode(_ code: String) -> String {
        code.replacingOccurrences(of: "_", with: "-").lowercased()
    }
}
