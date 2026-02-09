import Foundation

public enum SearchFilter {
    public static func filter(coins: [Coin], query: String) -> [Coin] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return coins }

        return coins.filter {
            $0.name.lowercased().contains(normalized) ||
            $0.symbol.lowercased().contains(normalized)
        }
    }
}
