import Foundation

public struct AppStoragePaths: Sendable {
    public let root: URL
    public let cacheDirectory: URL
    public let watchlistFile: URL
    public let settingsFile: URL
    public let coinListFile: URL
    public let pricesFile: URL
    public let sparklinesFile: URL
    public let detailsFile: URL

    public init(fileManager: FileManager = .default, appName: String = "TickerPad") {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        root = base.appendingPathComponent(appName, isDirectory: true)
        cacheDirectory = root.appendingPathComponent("cache", isDirectory: true)
        watchlistFile = root.appendingPathComponent("watchlist.json")
        settingsFile = root.appendingPathComponent("settings.json")
        coinListFile = cacheDirectory.appendingPathComponent("coins_list.json")
        pricesFile = cacheDirectory.appendingPathComponent("prices.json")
        sparklinesFile = cacheDirectory.appendingPathComponent("sparklines.json")
        detailsFile = cacheDirectory.appendingPathComponent("details.json")
    }

    public func createDirectoriesIfNeeded(fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
