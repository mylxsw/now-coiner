import Foundation

public enum ExchangeURLBuilder {
    public static func tradingView(symbol: String, exchange: Exchange, quote: String = "USDT") -> URL? {
        let full = "\(exchange.tradingViewPrefix):\(symbol.uppercased())\(quote.uppercased())"
        var components = URLComponents(string: "https://www.tradingview.com/chart/")
        components?.queryItems = [URLQueryItem(name: "symbol", value: full)]
        return components?.url
    }

    public static func exchange(symbol: String, coinID: String, exchange: Exchange) -> URL? {
        switch exchange {
        case .binance:
            return URL(string: "https://www.binance.com/trade/\(symbol.uppercased())_USDT")
        case .coinbase:
            return URL(string: "https://www.coinbase.com/price/\(coinID)")
        case .okx:
            return URL(string: "https://www.okx.com/trade-spot/\(symbol.lowercased())-usdt")
        }
    }
}
