import Foundation

public enum PriceFormatter {
    public static func currency(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code.uppercased()
        formatter.maximumFractionDigits = value >= 1000 ? 2 : 6
        formatter.minimumFractionDigits = value >= 1000 ? 2 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    public static func percent(_ value: Double) -> String {
        let sign = value >= 0 ? "▲" : "▼"
        return String(format: "%@ %.2f%%", sign, abs(value))
    }

    /// Compact currency string using the short symbol (e.g. "$" instead of "US$").
    public static func compactCurrency(_ value: Double, code: String) -> String {
        let shortSymbol = currencyShortSymbol(for: code)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value >= 1000 ? 2 : 6
        formatter.minimumFractionDigits = value >= 1000 ? 2 : 2
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(shortSymbol)\(number)"
    }

    /// Abbreviated compact currency for space-limited contexts (e.g. "$2.1K", "$87.3", "$0.096").
    public static func abbreviatedCurrency(_ value: Double, code: String) -> String {
        let shortSymbol = currencyShortSymbol(for: code)
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        let formatted: String
        if absValue >= 1_000_000_000 {
            formatted = String(format: "%.1fB", absValue / 1_000_000_000)
        } else if absValue >= 1_000_000 {
            formatted = String(format: "%.1fM", absValue / 1_000_000)
        } else if absValue >= 1_000 {
            formatted = String(format: "%.1fK", absValue / 1_000)
        } else if absValue >= 1 {
            formatted = String(format: "%.1f", absValue)
        } else {
            formatted = String(format: "%.3f", absValue)
        }

        return "\(sign)\(shortSymbol)\(formatted)"
    }

    private static func currencyShortSymbol(for code: String) -> String {
        switch code.lowercased() {
        case "usd": return "$"
        case "eur": return "€"
        case "gbp": return "£"
        case "cny": return "¥"
        case "jpy": return "¥"
        default:
            return code.uppercased() + " "
        }
    }

    public static func menuBarText(
        symbol: String,
        price: Double,
        changePercent: Double,
        currencyCode: String,
        style: MenuBarStyle
    ) -> String {
        let s = symbol.uppercased()
        let p = compactCurrency(price, code: currencyCode)
        let c = percent(changePercent)

        switch style {
        case .priceOnly:
            return p
        case .symbolAndPrice:
            return "\(s) \(p)"
        case .symbolAndChange:
            return "\(s) \(c)"
        case .full:
            return "\(s) \(p) \(c)"
        }
    }
}
