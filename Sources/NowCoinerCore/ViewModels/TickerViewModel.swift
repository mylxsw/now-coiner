import Foundation
import Combine

public struct CoinRowState: Identifiable, Equatable, Sendable {
    public let id: String
    public let coin: Coin
    public var price: CoinPrice?
    public var sparkline: SparklineData?
    public var isPinned: Bool
    public var isSelected: Bool

    public init(
        id: String,
        coin: Coin,
        price: CoinPrice?,
        sparkline: SparklineData?,
        isPinned: Bool,
        isSelected: Bool
    ) {
        self.id = id
        self.coin = coin
        self.price = price
        self.sparkline = sparkline
        self.isPinned = isPinned
        self.isSelected = isSelected
    }
}

@MainActor
public final class TickerViewModel: ObservableObject {
    @Published public private(set) var settings: AppSettings
    @Published public private(set) var coins: [Coin] = []
    @Published public private(set) var watchlist: [WatchlistItem] = []
    @Published public private(set) var prices: [String: CoinPrice] = [:]
    @Published public private(set) var sparklines: [String: SparklineData] = [:]
    @Published public var selectedCoinID: String?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let coinGecko: CoinGeckoServicing
    private let binance: BinanceServicing
    private let webSocketManager: WebSocketManaging
    private let settingsStore: SettingsStore
    private let watchlistStore: WatchlistStore
    private let cacheStore: CoinCacheStore

    private var realtimeTask: Task<Void, Never>?
    private var simpleRefreshTask: Task<Void, Never>?
    private var sparklineRefreshTask: Task<Void, Never>?

    private var detailCache: [String: DetailCacheEntry] = [:]

    public init(
        coinGecko: CoinGeckoServicing,
        binance: BinanceServicing,
        webSocketManager: WebSocketManaging,
        settingsStore: SettingsStore,
        watchlistStore: WatchlistStore,
        cacheStore: CoinCacheStore
    ) {
        self.coinGecko = coinGecko
        self.binance = binance
        self.webSocketManager = webSocketManager
        self.settingsStore = settingsStore
        self.watchlistStore = watchlistStore
        self.cacheStore = cacheStore
        self.settings = .default
    }

    deinit {
        realtimeTask?.cancel()
        simpleRefreshTask?.cancel()
        sparklineRefreshTask?.cancel()
    }

    public var visibleRows: [CoinRowState] {
        watchlist
            .sorted { a, b in
                if a.isPinned != b.isPinned { return a.isPinned }
                return a.sortOrder < b.sortOrder
            }
            .compactMap { item in
                guard let coin = coins.first(where: { $0.id == item.coinID }) else { return nil }
                return CoinRowState(
                    id: coin.id,
                    coin: coin,
                    price: prices[coin.id],
                    sparkline: sparklines[coin.id],
                    isPinned: item.isPinned,
                    isSelected: selectedCoinID == coin.id
                )
            }
    }

    public var menuBarRows: [CoinRowState] {
        Array(visibleRows.filter(\.isPinned).prefix(Self.maxPinnedCount))
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        settings = settingsStore.load()
        watchlist = watchlistStore.load()
        prices = cacheStore.loadPrices()
        sparklines = cacheStore.loadSparklines()
        detailCache = cacheStore.loadDetails()

        let cachedCoins = cacheStore.loadCoins()
        if !cachedCoins.isEmpty {
            coins = cachedCoins
        }

        await refreshCoinListIfNeeded(force: true)

        if watchlist.isEmpty {
            let defaults = ["bitcoin", "ethereum", "binancecoin", "solana", "uniswap", "cosmos", "algorand"]
            watchlist = defaults.enumerated().map { idx, id in
                WatchlistItem(coinID: id, sortOrder: idx, isPinned: idx < 3)
            }
            watchlistStore.save(watchlist)
        }

        if selectedCoinID == nil {
            selectedCoinID = watchlist.first?.coinID
        }

        await refreshMarketData(includeSparkline: true)
        await configureRuntimeTasks()
    }

    public func shutdown() async {
        persistStateSnapshot()

        realtimeTask?.cancel()
        realtimeTask = nil

        simpleRefreshTask?.cancel()
        simpleRefreshTask = nil

        sparklineRefreshTask?.cancel()
        sparklineRefreshTask = nil

        await webSocketManager.disconnect()
    }

    /// Force-persist current state. Used as a final safeguard before app termination.
    public func persistStateSnapshot() {
        settingsStore.save(settings)
        watchlistStore.save(watchlist)
        cacheStore.saveCoins(coins)
        cacheStore.savePrices(prices)
        cacheStore.saveSparklines(sparklines)
        cacheStore.saveDetails(detailCache)
    }

    public func refreshMarketData(includeSparkline: Bool = false) async {
        let ids = watchlist.map(\.coinID)
        guard !ids.isEmpty else { return }

        do {
            let markets = try await coinGecko.fetchMarkets(ids: ids, vsCurrency: settings.vsCurrency, includeSparkline: includeSparkline)
            var nextCoins = coins
            for market in markets {
                if !nextCoins.contains(where: { $0.id == market.coin.id }) {
                    nextCoins.append(market.coin)
                }
                prices[market.coin.id] = market.price
                if let sparkline = market.sparkline {
                    sparklines[market.coin.id] = sparkline
                }
            }
            coins = nextCoins
            cacheStore.saveCoins(nextCoins)
            cacheStore.savePrices(prices)
            cacheStore.saveSparklines(sparklines)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refreshSimplePrices() async {
        let ids = watchlist.map(\.coinID)
        guard !ids.isEmpty else { return }

        do {
            let values = try await coinGecko.fetchSimplePrices(ids: ids, vsCurrency: settings.vsCurrency)
            for (coinID, data) in values {
                var current = prices[coinID] ?? CoinPrice(
                    coinID: coinID,
                    currentPrice: data.price,
                    priceChange24h: 0,
                    priceChangePercent24h: data.change24h ?? 0
                )
                current.currentPrice = data.price
                current.priceChangePercent24h = data.change24h ?? current.priceChangePercent24h
                current.marketCap = data.marketCap
                current.totalVolume = data.volume24h
                current.lastUpdated = Date()
                prices[coinID] = current
            }
            cacheStore.savePrices(prices)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refreshBinancePrices() async {
        let symbolPairs = watchlist.compactMap { item in
            coins.first(where: { $0.id == item.coinID })?.binanceSymbol
        }
        guard !symbolPairs.isEmpty else { return }

        do {
            let data = try await binance.fetchTickerPrices(symbols: symbolPairs)
            let tuples: [(String, String)] = coins.compactMap { coin in
                guard let symbol = coin.binanceSymbol else { return nil }
                return (symbol, coin.id)
            }
            let mapping = Dictionary(uniqueKeysWithValues: tuples)

            for (symbol, value) in data {
                guard let id = mapping[symbol] else { continue }
                var current = prices[id] ?? CoinPrice(coinID: id, currentPrice: value, priceChange24h: 0, priceChangePercent24h: 0)
                current.currentPrice = value
                current.lastUpdated = Date()
                prices[id] = current
            }
            cacheStore.savePrices(prices)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func fetchCoinDetail(coinID: String) async -> CoinDetail? {
        if let cached = detailCache[coinID], Date().timeIntervalSince(cached.fetchedAt) < 600 {
            return cached.detail
        }

        do {
            let detail = try await coinGecko.fetchDetail(coinID: coinID, vsCurrency: settings.vsCurrency)
            detailCache[coinID] = DetailCacheEntry(detail: detail, fetchedAt: Date())
            cacheStore.saveDetails(detailCache)
            return detail
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    public func addCoin(_ coin: Coin) async {
        if !coins.contains(where: { $0.id == coin.id }) {
            coins.append(coin)
            cacheStore.saveCoins(coins)
        }

        guard !watchlist.contains(where: { $0.coinID == coin.id }) else { return }
        let item = WatchlistItem(coinID: coin.id, sortOrder: watchlist.count)
        watchlist.append(item)
        watchlistStore.save(watchlist)
        if selectedCoinID == nil {
            selectedCoinID = coin.id
        }
        await refreshMarketData(includeSparkline: false)
        await configureRuntimeTasks()
    }

    public func removeCoin(coinID: String) async {
        watchlist.removeAll { $0.coinID == coinID }
        reindexWatchlist()
        if selectedCoinID == coinID {
            selectedCoinID = watchlist.first?.coinID
        }
        watchlistStore.save(watchlist)
        await configureRuntimeTasks()
    }

    public func moveCoinToTop(coinID: String) async {
        guard let index = watchlist.firstIndex(where: { $0.coinID == coinID }) else { return }
        let item = watchlist.remove(at: index)
        watchlist.insert(item, at: 0)
        reindexWatchlist()
        watchlistStore.save(watchlist)
    }

    public func moveCoin(from source: IndexSet, to destination: Int) async {
        watchlist = movedArray(watchlist, from: source, to: destination)
        reindexWatchlist()
        watchlistStore.save(watchlist)
    }

    public static let maxPinnedCount = 3

    /// Toggle pin for a coin. Returns `false` if the pin limit is reached.
    @discardableResult
    public func togglePin(coinID: String) -> Bool {
        guard let index = watchlist.firstIndex(where: { $0.coinID == coinID }) else { return false }
        if !watchlist[index].isPinned {
            let currentPinned = watchlist.filter(\.isPinned).count
            if currentPinned >= Self.maxPinnedCount { return false }
        }
        watchlist[index].isPinned.toggle()
        watchlistStore.save(watchlist)
        return true
    }

    public func updateSettings(_ update: (inout AppSettings) -> Void) {
        var next = settings
        update(&next)
        settings = next
        settingsStore.save(next)
        Task { [weak self] in
            await self?.configureRuntimeTasks()
        }
    }

    public func selectionToggle(coinID: String) {
        selectedCoinID = selectedCoinID == coinID ? nil : coinID
    }

    public func selectNextRow() {
        let ordered = visibleRows.map(\.id)
        guard !ordered.isEmpty else {
            selectedCoinID = nil
            return
        }

        guard let current = selectedCoinID,
              let index = ordered.firstIndex(of: current) else {
            selectedCoinID = ordered.first
            return
        }

        let nextIndex = min(index + 1, ordered.count - 1)
        selectedCoinID = ordered[nextIndex]
    }

    public func selectPreviousRow() {
        let ordered = visibleRows.map(\.id)
        guard !ordered.isEmpty else {
            selectedCoinID = nil
            return
        }

        guard let current = selectedCoinID,
              let index = ordered.firstIndex(of: current) else {
            selectedCoinID = ordered.first
            return
        }

        let previousIndex = max(index - 1, 0)
        selectedCoinID = ordered[previousIndex]
    }

    public func selectedCoinForDetail() -> String? {
        selectedCoinID
    }

    public func applyWebSocketTick(_ tick: WebSocketTick) {
        guard let coinID = coins.first(where: { $0.binanceSymbol?.uppercased() == tick.symbol.uppercased() })?.id else {
            return
        }

        var current = prices[coinID] ?? CoinPrice(
            coinID: coinID,
            currentPrice: tick.currentPrice,
            priceChange24h: 0,
            priceChangePercent24h: 0
        )

        current.currentPrice = tick.currentPrice
        current.lastUpdated = Date()
        prices[coinID] = current
    }

    private func refreshCoinListIfNeeded(force: Bool) async {
        guard force else { return }
        do {
            let values = try await coinGecko.fetchCoinList()
            coins = values
            cacheStore.saveCoins(values)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func configureRuntimeTasks() async {
        simpleRefreshTask?.cancel()
        simpleRefreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let sleepSeconds: TimeInterval = self.settings.refreshInterval == .realtime ? 60 : self.settings.refreshInterval.seconds
                try? await Task.sleep(for: .seconds(sleepSeconds))
                guard !Task.isCancelled else { return }
                if self.settings.defaultDataSource == .binance, self.settings.refreshInterval != .realtime {
                    await self.refreshBinancePrices()
                } else {
                    await self.refreshSimplePrices()
                }
            }
        }

        sparklineRefreshTask?.cancel()
        sparklineRefreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                guard !Task.isCancelled else { return }
                await self.refreshMarketData(includeSparkline: true)
            }
        }

        realtimeTask?.cancel()
        realtimeTask = nil

        if settings.refreshInterval == .realtime {
            let symbols = watchlist.compactMap { item in
                coins.first(where: { $0.id == item.coinID })?.binanceSymbol
            }

            await webSocketManager.connect(symbols: symbols)

            realtimeTask = Task { [weak self] in
                guard let self else { return }
                for await tick in webSocketManager.ticks {
                    if Task.isCancelled { return }
                    await MainActor.run {
                        self.applyWebSocketTick(tick)
                    }
                }
            }
        } else {
            await webSocketManager.disconnect()
        }
    }

    private func reindexWatchlist() {
        for index in watchlist.indices {
            watchlist[index].sortOrder = index
        }
    }

    private func movedArray(_ array: [WatchlistItem], from source: IndexSet, to destination: Int) -> [WatchlistItem] {
        var values = array
        let moving = source.sorted().map { values[$0] }
        for index in source.sorted(by: >) {
            values.remove(at: index)
        }

        var target = destination
        let removedBeforeTarget = source.filter { $0 < destination }.count
        target -= removedBeforeTarget
        target = max(0, min(target, values.count))
        values.insert(contentsOf: moving, at: target)
        return values
    }
}
