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

    public static func menuBarText(
        symbol: String,
        price: Double,
        changePercent: Double,
        currencyCode: String,
        style: MenuBarStyle
    ) -> String {
        let s = symbol.uppercased()
        let p = currency(price, code: currencyCode)
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
