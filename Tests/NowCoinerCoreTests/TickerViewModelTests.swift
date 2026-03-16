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

    func testPinAndSettingsPersistToDisk() async throws {
        let coin = Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT")
        let market = CoinMarket(
            coin: coin,
            price: CoinPrice(coinID: "bitcoin", currentPrice: 100, priceChange24h: 1, priceChangePercent24h: 1)
        )
        let gecko = MockCoinGeckoService(coins: [coin], markets: [market])
        let binance = MockBinanceService(prices: ["BTCUSDT": 101])
        let webSocket = StubWebSocketManager()

        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let settingsURL = dir.appendingPathComponent("settings.json")
        let watchlistURL = dir.appendingPathComponent("watchlist.json")

        let settings = SettingsStore(url: settingsURL)
        let watchlist = WatchlistStore(url: watchlistURL)
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
        vm.updateSettings { $0.vsCurrency = "eur" }
        _ = vm.togglePin(coinID: "bitcoin")
        XCTAssertTrue(vm.togglePin(coinID: "solana"))
        vm.persistStateSnapshot()

        let savedSettingsData = try Data(contentsOf: settingsURL)
        XCTAssertTrue(String(decoding: savedSettingsData, as: UTF8.self).contains("\"vsCurrency\" : \"usd\""))

        let savedWatchlistData = try Data(contentsOf: watchlistURL)
        XCTAssertTrue(String(decoding: savedWatchlistData, as: UTF8.self).contains("\"coinID\" : \"solana\""))
        XCTAssertTrue(String(decoding: savedWatchlistData, as: UTF8.self).contains("\"isPinned\" : true"))
    }

    /// Simulate app restart: VM1 modifies data, VM2 loads from same files and verifies.
    func testDataSurvivesRestart() async throws {
        let coin = Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT")
        let market = CoinMarket(
            coin: coin,
            price: CoinPrice(coinID: "bitcoin", currentPrice: 100, priceChange24h: 1, priceChangePercent24h: 1)
        )

        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let settingsURL = dir.appendingPathComponent("settings.json")
        let watchlistURL = dir.appendingPathComponent("watchlist.json")
        let coinsURL = dir.appendingPathComponent("coins.json")
        let pricesURL = dir.appendingPathComponent("prices.json")
        let sparklinesURL = dir.appendingPathComponent("sparklines.json")
        let detailsURL = dir.appendingPathComponent("details.json")

        // --- Session 1: load defaults, modify pin, shut down ---
        do {
            let gecko = MockCoinGeckoService(coins: [coin], markets: [market])
            let vm = TickerViewModel(
                coinGecko: gecko,
                binance: MockBinanceService(prices: [:]),
                webSocketManager: StubWebSocketManager(),
                settingsStore: SettingsStore(url: settingsURL),
                watchlistStore: WatchlistStore(url: watchlistURL),
                cacheStore: CoinCacheStore(coinURL: coinsURL, priceURL: pricesURL, sparklineURL: sparklinesURL, detailURL: detailsURL)
            )
            await vm.load()

            // Defaults: bitcoin(pinned), ethereum(pinned), binancecoin(pinned), solana, uniswap, cosmos, algorand
            XCTAssertEqual(vm.watchlist.count, 7, "Should have 7 default items")
            XCTAssertTrue(vm.watchlist.first(where: { $0.coinID == "ethereum" })!.isPinned, "ethereum should be pinned by default")

            // Unpin ethereum
            let result = vm.togglePin(coinID: "ethereum")
            XCTAssertTrue(result, "togglePin should succeed")
            XCTAssertFalse(vm.watchlist.first(where: { $0.coinID == "ethereum" })!.isPinned, "ethereum should now be unpinned")

            // Verify file on disk
            let raw = try String(contentsOf: watchlistURL, encoding: .utf8)
            print("SESSION 1 - watchlist.json after togglePin:\n\(raw)")

            await vm.shutdown()
        }

        // --- Session 2: new VM with same file paths, verify data ---
        do {
            let gecko = MockCoinGeckoService(coins: [coin], markets: [market])
            let vm2 = TickerViewModel(
                coinGecko: gecko,
                binance: MockBinanceService(prices: [:]),
                webSocketManager: StubWebSocketManager(),
                settingsStore: SettingsStore(url: settingsURL),
                watchlistStore: WatchlistStore(url: watchlistURL),
                cacheStore: CoinCacheStore(coinURL: coinsURL, priceURL: pricesURL, sparklineURL: sparklinesURL, detailURL: detailsURL)
            )
            await vm2.load()

            print("SESSION 2 - watchlist after load: \(vm2.watchlist.map { "\($0.coinID):\($0.isPinned)" })")

            XCTAssertEqual(vm2.watchlist.count, 7, "Should still have 7 items after restart")

            let eth = vm2.watchlist.first(where: { $0.coinID == "ethereum" })
            XCTAssertNotNil(eth, "ethereum should still be in watchlist")
            XCTAssertFalse(eth!.isPinned, "ethereum should STILL be unpinned after restart — THIS IS THE BUG if it fails")

            await vm2.shutdown()
        }

        try FileManager.default.removeItem(at: dir)
    }

    func testTrialModeLimitsMenuBarToSingleCoin() async {
        let coins = [
            Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT"),
            Coin(id: "ethereum", symbol: "eth", name: "Ethereum", binanceSymbol: "ETHUSDT"),
            Coin(id: "solana", symbol: "sol", name: "Solana", binanceSymbol: "SOLUSDT")
        ]
        let markets = coins.map { coin in
            CoinMarket(
                coin: coin,
                price: CoinPrice(coinID: coin.id, currentPrice: 100, priceChange24h: 1, priceChangePercent24h: 1)
            )
        }

        let vm = makeViewModel(
            coins: coins,
            markets: markets,
            purchaseValidator: StaticPurchaseValidator(state: .trial)
        )

        await vm.load()

        XCTAssertTrue(vm.isTrialMode)
        XCTAssertEqual(vm.menuBarRows.count, 1)
    }

    func testTrialModePreventsWatchlistEdits() async {
        let coin = Coin(id: "dogecoin", symbol: "doge", name: "Dogecoin", binanceSymbol: "DOGEUSDT")
        let existingCoins = [
            Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT"),
            Coin(id: "ethereum", symbol: "eth", name: "Ethereum", binanceSymbol: "ETHUSDT")
        ]
        let markets = existingCoins.map { coin in
            CoinMarket(
                coin: coin,
                price: CoinPrice(coinID: coin.id, currentPrice: 100, priceChange24h: 1, priceChangePercent24h: 1)
            )
        }

        let vm = makeViewModel(
            coins: existingCoins + [coin],
            markets: markets,
            purchaseValidator: StaticPurchaseValidator(state: .trial)
        )

        await vm.load()
        let originalWatchlist = vm.watchlist

        await vm.addCoin(coin)
        XCTAssertEqual(vm.watchlist, originalWatchlist)

        XCTAssertFalse(vm.togglePin(coinID: "ethereum"))
        XCTAssertEqual(vm.watchlist, originalWatchlist)

        await vm.removeCoin(coinID: "ethereum")
        XCTAssertEqual(vm.watchlist, originalWatchlist)
    }

    func testTrialModePreventsLockedDisplaySettingsChanges() async {
        let coin = Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", binanceSymbol: "BTCUSDT")
        let market = CoinMarket(
            coin: coin,
            price: CoinPrice(coinID: coin.id, currentPrice: 100, priceChange24h: 1, priceChangePercent24h: 1)
        )

        let vm = makeViewModel(
            coins: [coin],
            markets: [market],
            purchaseValidator: StaticPurchaseValidator(state: .trial)
        )

        await vm.load()
        let original = vm.settings

        vm.updateSettings {
            $0.menuBarDisplayStyle = .full
            $0.menuBarCoinDisplayMode = .icon
            $0.priceColorScheme = .redUpGreenDown
            $0.menuBarUsePriceColor = true
        }

        XCTAssertEqual(vm.settings.menuBarDisplayStyle, original.menuBarDisplayStyle)
        XCTAssertEqual(vm.settings.menuBarCoinDisplayMode, original.menuBarCoinDisplayMode)
        XCTAssertEqual(vm.settings.priceColorScheme, original.priceColorScheme)
        XCTAssertEqual(vm.settings.menuBarUsePriceColor, original.menuBarUsePriceColor)
    }

    private func makeViewModel(
        coins: [Coin],
        markets: [CoinMarket],
        purchaseValidator: any PurchaseValidating = StaticPurchaseValidator(state: .purchased)
    ) -> TickerViewModel {
        let gecko = MockCoinGeckoService(coins: coins, markets: markets)
        let binance = MockBinanceService(prices: [:])
        let webSocket = StubWebSocketManager()

        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        return TickerViewModel(
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
            ),
            purchaseValidator: purchaseValidator
        )
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
