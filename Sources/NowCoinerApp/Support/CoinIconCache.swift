import Foundation
import AppKit
import NowCoinerCore

actor CoinIconCache {
    static let shared = CoinIconCache()

    private let fileManager: FileManager
    private let iconsDirectory: URL
    private let ttl: TimeInterval

    private var memoryCache: [String: Data] = [:]
    private var inflight: [String: Task<Data?, Never>] = [:]

    init(
        fileManager: FileManager = .default,
        paths: AppStoragePaths = AppStoragePaths(),
        ttl: TimeInterval = 24 * 60 * 60
    ) {
        self.fileManager = fileManager
        self.iconsDirectory = paths.cacheDirectory.appendingPathComponent("icons", isDirectory: true)
        self.ttl = ttl
        try? fileManager.createDirectory(at: iconsDirectory, withIntermediateDirectories: true)
    }

    func imageData(coinID: String, imageURL: String?) async -> Data? {
        guard let imageURL, let url = URL(string: imageURL) else { return nil }
        let key = cacheKey(for: coinID)

        if let cached = memoryCache[key] {
            if isStale(key: key) {
                triggerRefresh(key: key, remoteURL: url)
            }
            return cached
        }

        if let disk = loadFromDisk(key: key) {
            memoryCache[key] = disk
            if isStale(key: key) {
                triggerRefresh(key: key, remoteURL: url)
            }
            return disk
        }

        return await fetchAndStore(key: key, remoteURL: url)
    }

    func prefetch(coins: [Coin]) {
        for coin in coins {
            guard let imageURL = coin.imageURL else { continue }
            Task {
                _ = await imageData(coinID: coin.id, imageURL: imageURL)
            }
        }
    }

    private func triggerRefresh(key: String, remoteURL: URL) {
        guard inflight[key] == nil else { return }
        let task = Task<Data?, Never> { [weak self] in
            guard let self else { return nil }
            return await self.fetchAndStore(key: key, remoteURL: remoteURL)
        }
        inflight[key] = task
    }

    private func fetchAndStore(key: String, remoteURL: URL) async -> Data? {
        if let task = inflight[key] {
            return await task.value
        }

        let task = Task<Data?, Never> {
            do {
                let (data, response) = try await URLSession.shared.data(from: remoteURL)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), !data.isEmpty else {
                    return nil
                }
                return data
            } catch {
                return nil
            }
        }

        inflight[key] = task
        let data = await task.value
        inflight[key] = nil

        guard let data else { return loadFromDisk(key: key) ?? memoryCache[key] }

        memoryCache[key] = data
        let destination = fileURL(for: key)
        try? data.write(to: destination, options: .atomic)
        return data
    }

    private func loadFromDisk(key: String) -> Data? {
        let url = fileURL(for: key)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    private func isStale(key: String) -> Bool {
        let url = fileURL(for: key)
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let date = attrs[.modificationDate] as? Date else {
            return true
        }
        return Date().timeIntervalSince(date) > ttl
    }

    private func fileURL(for key: String) -> URL {
        iconsDirectory.appendingPathComponent("\(key).img")
    }

    private func cacheKey(for coinID: String) -> String {
        coinID.lowercased().replacingOccurrences(of: "/", with: "_")
    }
}

@MainActor
final class CoinIconLoader: ObservableObject {
    @Published var image: NSImage?

    private var task: Task<Void, Never>?

    func load(coinID: String, imageURL: String?) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            let data = await CoinIconCache.shared.imageData(coinID: coinID, imageURL: imageURL)
            guard !Task.isCancelled, let data, let image = NSImage(data: data) else { return }
            self.image = image
        }
    }

    deinit {
        task?.cancel()
    }
}
