import XCTest
@testable import TickerPadCore

@MainActor
final class TickerRealtimeTests: XCTestCase {
    func testApplyWebSocketTickUpdatesPrice() async {
        let coin = Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT")
        let gecko = MockGecko(coins: [coin])
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
        vm.applyWebSocketTick(WebSocketTick(symbol: "BTCUSDT", currentPrice: 12345.0))

        XCTAssertEqual(vm.prices["bitcoin"]?.currentPrice, 12345.0)
        await vm.shutdown()
    }
}

private struct MockGecko: CoinGeckoServicing {
    let coins: [Coin]

    func fetchCoinList() async throws -> [Coin] { coins }

    func fetchMarkets(ids: [String], vsCurrency: String, includeSparkline: Bool) async throws -> [CoinMarket] {
        ids.compactMap { id in
            guard let coin = coins.first(where: { $0.id == id }) else { return nil }
            return CoinMarket(coin: coin, price: CoinPrice(coinID: id, currentPrice: 1, priceChange24h: 0, priceChangePercent24h: 0))
        }
    }

    func fetchSimplePrices(ids: [String], vsCurrency: String) async throws -> [String : CoinSimplePrice] { [:] }

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
