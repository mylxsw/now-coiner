import Foundation
import Combine

@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public var query: String = ""
    @Published public private(set) var results: [Coin] = []

    private let allCoins: [Coin]
    private var debounceTask: Task<Void, Never>?

    public init(allCoins: [Coin]) {
        self.allCoins = allCoins
        self.results = allCoins
    }

    public func handleQueryChange() {
        debounceTask?.cancel()
        let value = query

        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            results = SearchFilter.filter(coins: allCoins, query: value)
        }
    }

    public func isAdded(_ coinID: String, watchlist: [WatchlistItem]) -> Bool {
        watchlist.contains(where: { $0.coinID == coinID })
    }
}
