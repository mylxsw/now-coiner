import Foundation

public enum ExchangeURLBuilder {
    public static func tradingView(symbol: String, exchange: Exchange, quote: String = "USDT") -> URL? {
        guard let safeSymbol = sanitizedSymbol(symbol),
              let safeQuote = sanitizedSymbol(quote) else {
            return nil
        }
        let full = "\(exchange.tradingViewPrefix):\(safeSymbol)\(safeQuote)"
        var components = URLComponents(string: "https://www.tradingview.com/chart/")
        components?.queryItems = [URLQueryItem(name: "symbol", value: full)]
        return components?.url
    }

    public static func exchange(symbol: String, coinID: String, exchange: Exchange) -> URL? {
        switch exchange {
        case .binance:
            guard let safeSymbol = sanitizedSymbol(symbol) else { return nil }
            return URL(string: "https://www.binance.com/trade/\(safeSymbol)_USDT")
        case .coinbase:
            guard let safeCoinID = encodedPathComponent(coinID) else { return nil }
            return URL(string: "https://www.coinbase.com/price/\(safeCoinID)")
        case .okx:
            guard let safeSymbol = sanitizedSymbol(symbol)?.lowercased() else { return nil }
            return URL(string: "https://www.okx.com/trade-spot/\(safeSymbol)-usdt")
        }
    }

    private static func sanitizedSymbol(_ value: String) -> String? {
        let candidate = value.uppercased()
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        guard !candidate.isEmpty,
              candidate.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return nil
        }
        return candidate
    }

    private static func encodedPathComponent(_ value: String) -> String? {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return value.addingPercentEncoding(withAllowedCharacters: allowed)
    }
}
