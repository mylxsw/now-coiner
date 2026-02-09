import Foundation

public final class SettingsStore: @unchecked Sendable {
    private let fileStore: JSONFileStore<AppSettings>

    public init(url: URL) {
        self.fileStore = JSONFileStore(url: url)
    }

    public func load() -> AppSettings {
        (try? fileStore.load()) ?? .default
    }

    public func save(_ settings: AppSettings) {
        do {
            try fileStore.save(settings)
        } catch {
            NSLog("NowCoiner: failed to save settings: %@", error.localizedDescription)
        }
    }
}

public final class WatchlistStore: @unchecked Sendable {
    private let fileStore: JSONFileStore<[WatchlistItem]>

    public init(url: URL) {
        self.fileStore = JSONFileStore(url: url)
    }

    public func load() -> [WatchlistItem] {
        ((try? fileStore.load()) ?? [])
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    public func save(_ items: [WatchlistItem]) {
        do {
            try fileStore.save(items)
        } catch {
            NSLog("NowCoiner: failed to save watchlist: %@", error.localizedDescription)
        }
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

public final class CoinCacheStore: @unchecked Sendable {
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
        do {
            try coinStore.save(coins)
        } catch {
            NSLog("NowCoiner: failed to save coins cache: %@", error.localizedDescription)
        }
    }

    public func loadPrices() -> [String: CoinPrice] {
        (try? priceStore.load()) ?? [:]
    }

    public func savePrices(_ prices: [String: CoinPrice]) {
        do {
            try priceStore.save(prices)
        } catch {
            NSLog("NowCoiner: failed to save prices cache: %@", error.localizedDescription)
        }
    }

    public func loadSparklines() -> [String: SparklineData] {
        (try? sparklineStore.load()) ?? [:]
    }

    public func saveSparklines(_ values: [String: SparklineData]) {
        do {
            try sparklineStore.save(values)
        } catch {
            NSLog("NowCoiner: failed to save sparklines cache: %@", error.localizedDescription)
        }
    }

    public func loadDetails() -> [String: DetailCacheEntry] {
        (try? detailStore.load()) ?? [:]
    }

    public func saveDetails(_ values: [String: DetailCacheEntry]) {
        do {
            try detailStore.save(values)
        } catch {
            NSLog("NowCoiner: failed to save details cache: %@", error.localizedDescription)
        }
    }
}
