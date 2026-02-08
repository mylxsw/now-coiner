import Foundation

public actor SettingsStore {
    private let fileStore: JSONFileStore<AppSettings>

    public init(url: URL) {
        self.fileStore = JSONFileStore(url: url)
    }

    public func load() -> AppSettings {
        (try? fileStore.load()) ?? .default
    }

    public func save(_ settings: AppSettings) {
        try? fileStore.save(settings)
    }
}

public actor WatchlistStore {
    private let fileStore: JSONFileStore<[WatchlistItem]>

    public init(url: URL) {
        self.fileStore = JSONFileStore(url: url)
    }

    public func load() -> [WatchlistItem] {
        ((try? fileStore.load()) ?? [])
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    public func save(_ items: [WatchlistItem]) {
        try? fileStore.save(items)
    }
}

public struct DetailCacheEntry: Codable, Equatable, Sendable {
    public let detail: CoinDetail
    public let fetchedAt: Date

    public init(detail: CoinDetail, fetchedAt: Date) {
        self.detail = detail
        self.fetchedAt = fetchedAt
    }
}

public actor CoinCacheStore {
    private let coinStore: JSONFileStore<[Coin]>
    private let priceStore: JSONFileStore<[String: CoinPrice]>
    private let sparklineStore: JSONFileStore<[String: SparklineData]>
    private let detailStore: JSONFileStore<[String: DetailCacheEntry]>

    public init(coinURL: URL, priceURL: URL, sparklineURL: URL, detailURL: URL) {
        self.coinStore = JSONFileStore(url: coinURL)
        self.priceStore = JSONFileStore(url: priceURL)
        self.sparklineStore = JSONFileStore(url: sparklineURL)
        self.detailStore = JSONFileStore(url: detailURL)
    }

    public func loadCoins() -> [Coin] {
        (try? coinStore.load()) ?? []
    }

    public func saveCoins(_ coins: [Coin]) {
        try? coinStore.save(coins)
    }

    public func loadPrices() -> [String: CoinPrice] {
        (try? priceStore.load()) ?? [:]
    }

    public func savePrices(_ prices: [String: CoinPrice]) {
        try? priceStore.save(prices)
    }

    public func loadSparklines() -> [String: SparklineData] {
        (try? sparklineStore.load()) ?? [:]
    }

    public func saveSparklines(_ values: [String: SparklineData]) {
        try? sparklineStore.save(values)
    }

    public func loadDetails() -> [String: DetailCacheEntry] {
        (try? detailStore.load()) ?? [:]
    }

    public func saveDetails(_ values: [String: DetailCacheEntry]) {
        try? detailStore.save(values)
    }
}
