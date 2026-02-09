import XCTest
@testable import NowCoinerCore

@MainActor
final class TickerDetailCacheTests: XCTestCase {
    func testDetailUsesTenMinuteCacheAndPersists() async {
        let coin = Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT")
        let gecko = CountingGecko(coins: [coin])
        let binance = MockBinanceService(prices: [:])
        let webSocket = StubWebSocketManager()

        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let vm = TickerViewModel(
            coinGecko: gecko,
            binance: binance,
            webSocketManager: webSocket,
            settingsStore: SettingsStore(url: dir.appendingPathComponent("settings.json")),
            watchlistStore: WatchlistStore(url: dir.appendingPathComponent("watchlist.json")),
            cacheStore: CoinCacheStore(
                coinURL: dir.appendingPathComponent("coins.json"),
                priceURL: dir.appendingPathComponent("prices.json"),
                sparklineURL: dir.appendingPathComponent("sparklines.json"),
                detailURL: dir.appendingPathComponent("details.json")
            )
        )

        await vm.load()
        let first = await vm.fetchCoinDetail(coinID: "bitcoin")
        let second = await vm.fetchCoinDetail(coinID: "bitcoin")

        XCTAssertEqual(first?.id, "bitcoin")
        XCTAssertEqual(second?.id, "bitcoin")
        let count = await gecko.detailRequestCount()
        XCTAssertEqual(count, 1)

        await vm.shutdown()

        let vm2 = TickerViewModel(
            coinGecko: gecko,
            binance: binance,
            webSocketManager: webSocket,
            settingsStore: SettingsStore(url: dir.appendingPathComponent("settings.json")),
            watchlistStore: WatchlistStore(url: dir.appendingPathComponent("watchlist.json")),
            cacheStore: CoinCacheStore(
                coinURL: dir.appendingPathComponent("coins.json"),
                priceURL: dir.appendingPathComponent("prices.json"),
                sparklineURL: dir.appendingPathComponent("sparklines.json"),
                detailURL: dir.appendingPathComponent("details.json")
            )
        )
        await vm2.load()
        let third = await vm2.fetchCoinDetail(coinID: "bitcoin")
        XCTAssertEqual(third?.id, "bitcoin")
        let countAfterReload = await gecko.detailRequestCount()
        XCTAssertEqual(countAfterReload, 1)
        await vm2.shutdown()
    }

    func testSelectionNavigationMovesAcrossRows() async {
        let coins = [
            Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT"),
            Coin(id: "ethereum", symbol: "eth", name: "Ethereum", binanceSymbol: "ETHUSDT")
        ]
        let gecko = CountingGecko(coins: coins)

        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let vm = TickerViewModel(
            coinGecko: gecko,
            binance: MockBinanceService(prices: [:]),
            webSocketManager: StubWebSocketManager(),
            settingsStore: SettingsStore(url: dir.appendingPathComponent("settings.json")),
            watchlistStore: WatchlistStore(url: dir.appendingPathComponent("watchlist.json")),
            cacheStore: CoinCacheStore(
                coinURL: dir.appendingPathComponent("coins.json"),
                priceURL: dir.appendingPathComponent("prices.json"),
                sparklineURL: dir.appendingPathComponent("sparklines.json"),
                detailURL: dir.appendingPathComponent("details.json")
            )
        )

        await vm.load()
        XCTAssertEqual(vm.selectedCoinForDetail(), "bitcoin")

        vm.selectNextRow()
        XCTAssertEqual(vm.selectedCoinForDetail(), "ethereum")

        vm.selectPreviousRow()
        XCTAssertEqual(vm.selectedCoinForDetail(), "bitcoin")

        await vm.shutdown()
    }
}

private actor DetailCounter {
    private var count = 0

    func increment() {
        count += 1
    }

    func current() -> Int {
        count
    }
}

private struct CountingGecko: CoinGeckoServicing {
    let coins: [Coin]
    private let counter = DetailCounter()

    func fetchCoinList() async throws -> [Coin] { coins }

    func fetchMarkets(ids: [String], vsCurrency: String, includeSparkline: Bool) async throws -> [CoinMarket] {
        ids.compactMap { id in
            guard let coin = coins.first(where: { $0.id == id }) else { return nil }
            return CoinMarket(coin: coin, price: CoinPrice(coinID: id, currentPrice: 1, priceChange24h: 0, priceChangePercent24h: 0))
        }
    }

    func fetchSimplePrices(ids: [String], vsCurrency: String) async throws -> [String : CoinSimplePrice] { [:] }

    func fetchDetail(coinID: String, vsCurrency: String) async throws -> CoinDetail {
        await counter.increment()
        return CoinDetail(
            id: coinID,
            symbol: "btc",
            name: "Bitcoin",
            description: "",
            imageURL: "",
            currentPrice: 1,
            marketCap: 1,
            marketCapRank: 1,
            totalVolume: 1,
            high24h: 1,
            low24h: 1,
            priceChangePercentage24h: 1,
            priceChangePercentage7d: 1,
            priceChangePercentage30d: 1,
            circulatingSupply: 1,
            totalSupply: nil,
            maxSupply: nil,
            ath: 1,
            athDate: .now,
            atl: 1,
            atlDate: .now,
            homepage: nil,
            whitepaper: nil,
            blockchainSites: [],
            subredditURL: nil,
            twitterHandle: nil,
            githubRepos: [],
            githubStars: nil,
            githubForks: nil,
            commitCount4Weeks: nil,
            twitterFollowers: nil,
            redditSubscribers: nil
        )
    }

    func detailRequestCount() async -> Int {
        await counter.current()
    }
}

private struct MockBinanceService: BinanceServicing {
    var prices: [String: Double]

    func fetchTickerPrices(symbols: [String]) async throws -> [String : Double] {
        prices
    }
}
