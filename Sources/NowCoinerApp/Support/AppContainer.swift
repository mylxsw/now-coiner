import Foundation
import NowCoinerCore

struct AppContainer {
    let viewModel: TickerViewModel

    @MainActor
    static func makeDefault() -> AppContainer {
        migrateLegacyDataIfNeeded()

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
            cacheStore: cacheStore,
            purchaseValidator: AppStorePurchaseValidator()
        )

        return AppContainer(viewModel: viewModel)
    }

    private static func migrateLegacyDataIfNeeded(fileManager: FileManager = .default) {
        let now = AppStoragePaths(fileManager: fileManager, appName: "NowCoiner")
        let legacy = AppStoragePaths(fileManager: fileManager, appName: "TickerPad")

        let hasNowData = fileManager.fileExists(atPath: now.settingsFile.path)
            || fileManager.fileExists(atPath: now.watchlistFile.path)
        let hasLegacyData = fileManager.fileExists(atPath: legacy.settingsFile.path)
            || fileManager.fileExists(atPath: legacy.watchlistFile.path)

        guard !hasNowData, hasLegacyData else { return }

        try? now.createDirectoriesIfNeeded(fileManager: fileManager)

        let pairs: [(URL, URL)] = [
            (legacy.settingsFile, now.settingsFile),
            (legacy.watchlistFile, now.watchlistFile),
            (legacy.coinListFile, now.coinListFile),
            (legacy.pricesFile, now.pricesFile),
            (legacy.sparklinesFile, now.sparklinesFile),
            (legacy.detailsFile, now.detailsFile)
        ]

        for (source, target) in pairs {
            guard fileManager.fileExists(atPath: source.path),
                  !fileManager.fileExists(atPath: target.path) else { continue }
            try? fileManager.copyItem(at: source, to: target)
        }
    }
}
