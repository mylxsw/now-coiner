import XCTest
@testable import NowCoinerCore

@MainActor
final class TickerViewModelTests: XCTestCase {
    func testAddMovePinRemoveCoin() async {
        let coin = Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT")
        let market = CoinMarket(
            coin: coin,
            price: CoinPrice(coinID: "bitcoin", currentPrice: 100, priceChange24h: 1, priceChangePercent24h: 1)
        )
        let gecko = MockCoinGeckoService(coins: [coin], markets: [market])
        let binance = MockBinanceService(prices: ["BTCUSDT": 101])
        let webSocket = StubWebSocketManager()

        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let settings = SettingsStore(url: dir.appendingPathComponent("settings.json"))
        let watchlist = WatchlistStore(url: dir.appendingPathComponent("watchlist.json"))
        let cache = CoinCacheStore(
            coinURL: dir.appendingPathComponent("coins.json"),
            priceURL: dir.appendingPathComponent("prices.json"),
            sparklineURL: dir.appendingPathComponent("sparklines.json"),
                detailURL: dir.appendingPathComponent("details.json")
            )

        let vm = TickerViewModel(
            coinGecko: gecko,
            binance: binance,
            webSocketManager: webSocket,
            settingsStore: settings,
            watchlistStore: watchlist,
            cacheStore: cache
        )

        await vm.load()
        await vm.addCoin(coin)

        XCTAssertFalse(vm.watchlist.isEmpty)

        let pinBefore = vm.watchlist.first(where: { $0.coinID == "bitcoin" })?.isPinned ?? false
        _ = vm.togglePin(coinID: "bitcoin")
        let pinAfter = vm.watchlist.first(where: { $0.coinID == "bitcoin" })?.isPinned ?? false
        XCTAssertNotEqual(pinBefore, pinAfter)

        await vm.moveCoinToTop(coinID: "bitcoin")
        XCTAssertEqual(vm.watchlist.first?.coinID, "bitcoin")

        await vm.removeCoin(coinID: "bitcoin")
        XCTAssertFalse(vm.watchlist.contains(where: { $0.coinID == "bitcoin" }))

        await vm.shutdown()
    }
}

private struct MockCoinGeckoService: CoinGeckoServicing {
    var coins: [Coin]
    var markets: [CoinMarket]

    func fetchCoinList() async throws -> [Coin] { coins }

    func fetchMarkets(ids: [String], vsCurrency: String, includeSparkline: Bool) async throws -> [CoinMarket] {
        markets.filter { ids.contains($0.coin.id) }
    }

    func fetchSimplePrices(ids: [String], vsCurrency: String) async throws -> [String : CoinSimplePrice] {
        Dictionary(uniqueKeysWithValues: ids.map { id in
            (id, CoinSimplePrice(price: 1, marketCap: nil, volume24h: nil, change24h: nil, lastUpdatedAt: nil))
        })
    }

    func fetchDetail(coinID: String, vsCurrency: String) async throws -> CoinDetail {
        CoinDetail(
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
}

private struct MockBinanceService: BinanceServicing {
    var prices: [String: Double]

    func fetchTickerPrices(symbols: [String]) async throws -> [String : Double] {
        prices
    }
}
