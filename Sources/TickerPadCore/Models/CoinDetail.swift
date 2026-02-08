import Foundation

public struct CoinDetail: Codable, Equatable, Sendable {
    public let id: String
    public let symbol: String
    public let name: String
    public let description: String
    public let imageURL: String

    public let currentPrice: Double
    public let marketCap: Double
    public let marketCapRank: Int
    public let totalVolume: Double
    public let high24h: Double
    public let low24h: Double
    public let priceChangePercentage24h: Double
    public let priceChangePercentage7d: Double
    public let priceChangePercentage30d: Double
    public let circulatingSupply: Double
    public let totalSupply: Double?
    public let maxSupply: Double?
    public let ath: Double
    public let athDate: Date
    public let atl: Double
    public let atlDate: Date

    public let homepage: String?
    public let whitepaper: String?
    public let blockchainSites: [String]
    public let subredditURL: String?
    public let twitterHandle: String?
    public let githubRepos: [String]

    public let githubStars: Int?
    public let githubForks: Int?
    public let commitCount4Weeks: Int?

    public let twitterFollowers: Int?
    public let redditSubscribers: Int?
}
