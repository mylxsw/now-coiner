import Foundation

public enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decoding(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .statusCode(let code): return "Unexpected status code: \(code)"
        case .decoding(let message): return "Decoding failed: \(message)"
        }
    }
}

public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionHTTPClient: HTTPClient {
    public init() {}

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        return (data, response)
    }
}

public protocol CoinGeckoServicing: Sendable {
    func fetchCoinList() async throws -> [Coin]
    func fetchMarkets(ids: [String], vsCurrency: String, includeSparkline: Bool) async throws -> [CoinMarket]
    func fetchSimplePrices(ids: [String], vsCurrency: String) async throws -> [String: CoinSimplePrice]
    func fetchDetail(coinID: String, vsCurrency: String) async throws -> CoinDetail
}

public protocol BinanceServicing: Sendable {
    func fetchTickerPrices(symbols: [String]) async throws -> [String: Double]
}

public struct CoinMarket: Equatable, Sendable {
    public var coin: Coin
    public var price: CoinPrice
    public var sparkline: SparklineData?

    public init(coin: Coin, price: CoinPrice, sparkline: SparklineData? = nil) {
        self.coin = coin
        self.price = price
        self.sparkline = sparkline
    }
}

public struct CoinSimplePrice: Equatable, Sendable {
    public let price: Double
    public let marketCap: Double?
    public let volume24h: Double?
    public let change24h: Double?
    public let lastUpdatedAt: TimeInterval?

    public init(price: Double, marketCap: Double?, volume24h: Double?, change24h: Double?, lastUpdatedAt: TimeInterval?) {
        self.price = price
        self.marketCap = marketCap
        self.volume24h = volume24h
        self.change24h = change24h
        self.lastUpdatedAt = lastUpdatedAt
    }
}
