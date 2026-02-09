import Foundation

public struct Coin: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let symbol: String
    public let name: String
    public var imageURL: String?
    public var binanceSymbol: String?

    public init(
        id: String,
        symbol: String,
        name: String,
        imageURL: String? = nil,
        binanceSymbol: String? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.imageURL = imageURL
        self.binanceSymbol = binanceSymbol
    }
}

public struct CoinPrice: Codable, Equatable, Sendable {
    public let coinID: String
    public var currentPrice: Double
    public var priceChange24h: Double
    public var priceChangePercent24h: Double
    public var high24h: Double?
    public var low24h: Double?
    public var marketCap: Double?
    public var marketCapRank: Int?
    public var totalVolume: Double?
    public var lastUpdated: Date

    public init(
        coinID: String,
        currentPrice: Double,
        priceChange24h: Double,
        priceChangePercent24h: Double,
        high24h: Double? = nil,
        low24h: Double? = nil,
        marketCap: Double? = nil,
        marketCapRank: Int? = nil,
        totalVolume: Double? = nil,
        lastUpdated: Date = .now
    ) {
        self.coinID = coinID
        self.currentPrice = currentPrice
        self.priceChange24h = priceChange24h
        self.priceChangePercent24h = priceChangePercent24h
        self.high24h = high24h
        self.low24h = low24h
        self.marketCap = marketCap
        self.marketCapRank = marketCapRank
        self.totalVolume = totalVolume
        self.lastUpdated = lastUpdated
    }
}

public struct SparklineData: Codable, Equatable, Sendable {
    public let coinID: String
    public let prices: [Double]
    public let fetchedAt: Date

    public init(coinID: String, prices: [Double], fetchedAt: Date = .now) {
        self.coinID = coinID
        self.prices = prices
        self.fetchedAt = fetchedAt
    }
}

public struct WatchlistItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let coinID: String
    public var sortOrder: Int
    public var isPinned: Bool
    public let addedAt: Date

    public init(
        id: UUID = UUID(),
        coinID: String,
        sortOrder: Int,
        isPinned: Bool = false,
        addedAt: Date = .now
    ) {
        self.id = id
        self.coinID = coinID
        self.sortOrder = sortOrder
        self.isPinned = isPinned
        self.addedAt = addedAt
    }
}
