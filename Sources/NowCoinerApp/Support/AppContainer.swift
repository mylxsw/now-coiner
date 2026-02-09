import Foundation
import NowCoinerCore

struct AppContainer {
    let viewModel: TickerViewModel

    @MainActor
    static func makeDefault() -> AppContainer {
        let paths = AppStoragePaths()
        try? paths.createDirectoriesIfNeeded()

        let settingsStore = SettingsStore(url: paths.settingsFile)
        let watchlistStore = WatchlistStore(url: paths.watchlistFile)
        let cacheStore = CoinCacheStore(
            coinURL: paths.coinListFile,
            priceURL: paths.pricesFile,
            sparklineURL: paths.sparklinesFile,
            detailURL: paths.detailsFile
        )

        let viewModel = TickerViewModel(
            coinGecko: CoinGeckoService(),
            binance: BinanceService(),
            webSocketManager: BinanceWebSocketManager(),
            settingsStore: settingsStore,
            watchlistStore: watchlistStore,
            cacheStore: cacheStore
        )

        return AppContainer(viewModel: viewModel)
    }
}
