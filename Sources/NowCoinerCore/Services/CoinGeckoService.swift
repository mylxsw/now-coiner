import Foundation

public struct CoinGeckoService: CoinGeckoServicing {
    private let client: HTTPClient
    private let baseURL: URL
    private let demoAPIKey: String?

    public init(
        client: HTTPClient = URLSessionHTTPClient(),
        baseURL: URL = URL(string: "https://api.coingecko.com/api/v3")!,
        demoAPIKey: String? = ProcessInfo.processInfo.environment["COINGECKO_API_KEY"]
    ) {
        self.client = client
        self.baseURL = baseURL
        self.demoAPIKey = demoAPIKey
    }

    public func fetchCoinList() async throws -> [Coin] {
        let request = try request(path: "/coins/list") { components in
            components.queryItems = [
                URLQueryItem(name: "include_platform", value: "false")
            ]
        }

        let payload: [CoinListDTO] = try await decode(request, as: [CoinListDTO].self)
        return payload.map {
            Coin(id: $0.id, symbol: $0.symbol, name: $0.name)
        }
    }

    public func fetchMarkets(ids: [String], vsCurrency: String, includeSparkline: Bool) async throws -> [CoinMarket] {
        let request = try request(path: "/coins/markets") { components in
            var items: [URLQueryItem] = [
                URLQueryItem(name: "vs_currency", value: vsCurrency.lowercased()),
                URLQueryItem(name: "order", value: "market_cap_desc"),
                URLQueryItem(name: "sparkline", value: includeSparkline ? "true" : "false"),
                URLQueryItem(name: "price_change_percentage", value: "24h,7d"),
                URLQueryItem(name: "per_page", value: "250")
            ]
            if !ids.isEmpty {
                items.append(URLQueryItem(name: "ids", value: ids.joined(separator: ",")))
            }
            components.queryItems = items
        }

        let payload: [CoinMarketDTO] = try await decode(request, as: [CoinMarketDTO].self)
        return payload.map { dto in
            let coin = Coin(
                id: dto.id,
                symbol: dto.symbol,
                name: dto.name,
                imageURL: dto.image,
                binanceSymbol: dto.symbol.uppercased() + "USDT"
            )
            let price = CoinPrice(
                coinID: dto.id,
                currentPrice: dto.currentPrice,
                priceChange24h: dto.priceChange24h ?? 0,
                priceChangePercent24h: dto.priceChangePercent24h ?? 0,
                high24h: dto.high24h,
                low24h: dto.low24h,
                marketCap: dto.marketCap,
                marketCapRank: dto.marketCapRank,
                totalVolume: dto.totalVolume,
                lastUpdated: dto.lastUpdated.flatMap(ISO8601DateFormatter().date(from:)) ?? .now
            )
            let sparkline = dto.sparklineIn7d.map {
                SparklineData(coinID: dto.id, prices: $0.price)
            }
            return CoinMarket(coin: coin, price: price, sparkline: sparkline)
        }
    }

    public func fetchSimplePrices(ids: [String], vsCurrency: String) async throws -> [String: CoinSimplePrice] {
        guard !ids.isEmpty else { return [:] }

        let request = try request(path: "/simple/price") { components in
            components.queryItems = [
                URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
                URLQueryItem(name: "vs_currencies", value: vsCurrency.lowercased()),
                URLQueryItem(name: "include_market_cap", value: "true"),
                URLQueryItem(name: "include_24hr_vol", value: "true"),
                URLQueryItem(name: "include_24hr_change", value: "true"),
                URLQueryItem(name: "include_last_updated_at", value: "true")
            ]
        }

        let payload: [String: [String: Double]] = try await decode(request, as: [String: [String: Double]].self)
        let lowerCurrency = vsCurrency.lowercased()

        return payload.reduce(into: [String: CoinSimplePrice]()) { partial, entry in
            let id = entry.key
            let object = entry.value
            guard let price = object[lowerCurrency] else { return }

            partial[id] = CoinSimplePrice(
                price: price,
                marketCap: object["\(lowerCurrency)_market_cap"],
                volume24h: object["\(lowerCurrency)_24h_vol"],
                change24h: object["\(lowerCurrency)_24h_change"],
                lastUpdatedAt: object["last_updated_at"]
            )
        }
    }

    public func fetchDetail(coinID: String, vsCurrency: String) async throws -> CoinDetail {
        let request = try request(path: "/coins/\(coinID)") { components in
            components.queryItems = [
                URLQueryItem(name: "localization", value: "false"),
                URLQueryItem(name: "tickers", value: "false"),
                URLQueryItem(name: "market_data", value: "true"),
                URLQueryItem(name: "community_data", value: "true"),
                URLQueryItem(name: "developer_data", value: "true"),
                URLQueryItem(name: "sparkline", value: "true")
            ]
        }

        let dto: CoinDetailDTO = try await decode(request, as: CoinDetailDTO.self)
        let currency = vsCurrency.lowercased()
        let parser = ISO8601DateFormatter()

        return CoinDetail(
            id: dto.id,
            symbol: dto.symbol,
            name: dto.name,
            description: dto.description?.en ?? "",
            imageURL: dto.image?.large ?? "",
            currentPrice: dto.marketData?.currentPrice?[currency] ?? 0,
            marketCap: dto.marketData?.marketCap?[currency] ?? 0,
            marketCapRank: dto.marketCapRank ?? 0,
            totalVolume: dto.marketData?.totalVolume?[currency] ?? 0,
            high24h: dto.marketData?.high24h?[currency] ?? 0,
            low24h: dto.marketData?.low24h?[currency] ?? 0,
            priceChangePercentage24h: dto.marketData?.priceChangePercentage24h ?? 0,
            priceChangePercentage7d: dto.marketData?.priceChangePercentage7d ?? 0,
            priceChangePercentage30d: dto.marketData?.priceChangePercentage30d ?? 0,
            circulatingSupply: dto.marketData?.circulatingSupply ?? 0,
            totalSupply: dto.marketData?.totalSupply,
            maxSupply: dto.marketData?.maxSupply,
            ath: dto.marketData?.ath?[currency] ?? 0,
            athDate: dto.marketData?.athDate?[currency].flatMap(parser.date(from:)) ?? .distantPast,
            atl: dto.marketData?.atl?[currency] ?? 0,
            atlDate: dto.marketData?.atlDate?[currency].flatMap(parser.date(from:)) ?? .distantPast,
            homepage: dto.links?.homepage?.first(where: { !($0 ?? "").isEmpty }) ?? nil,
            whitepaper: dto.links?.whitepaper,
            blockchainSites: dto.links?.blockchainSite?.compactMap { $0 } ?? [],
            subredditURL: dto.links?.subredditURL,
            twitterHandle: dto.links?.twitterScreenName,
            githubRepos: dto.links?.reposURL?.github?.compactMap { $0 } ?? [],
            githubStars: dto.developerData?.stars,
            githubForks: dto.developerData?.forks,
            commitCount4Weeks: dto.developerData?.commitCount4Weeks,
            twitterFollowers: dto.communityData?.twitterFollowers,
            redditSubscribers: dto.communityData?.redditSubscribers
        )
    }

    private func request(path: String, configure: (inout URLComponents) -> Void) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        configure(&components)

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let key = demoAPIKey, !key.isEmpty {
            request.setValue(key, forHTTPHeaderField: "x-cg-demo-api-key")
        }

        return request
    }

    private func decode<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await client.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw NetworkError.statusCode(response.statusCode)
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NetworkError.decoding(error.localizedDescription)
        }
    }
}

private struct CoinListDTO: Codable {
    let id: String
    let symbol: String
    let name: String
}

private struct CoinMarketDTO: Codable {
    let id: String
    let symbol: String
    let name: String
    let image: String?
    let currentPrice: Double
    let marketCap: Double?
    let marketCapRank: Int?
    let totalVolume: Double?
    let high24h: Double?
    let low24h: Double?
    let priceChange24h: Double?
    let priceChangePercent24h: Double?
    let sparklineIn7d: SparklinePayload?
    let lastUpdated: String?

    struct SparklinePayload: Codable {
        let price: [Double]
    }

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice = "current_price"
        case marketCap = "market_cap"
        case marketCapRank = "market_cap_rank"
        case totalVolume = "total_volume"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case priceChange24h = "price_change_24h"
        case priceChangePercent24h = "price_change_percentage_24h"
        case sparklineIn7d = "sparkline_in_7d"
        case lastUpdated = "last_updated"
    }
}

private struct CoinDetailDTO: Codable {
    struct DescriptionPayload: Codable {
        let en: String?
    }

    struct ImagePayload: Codable {
        let large: String?
    }

    struct LinksPayload: Codable {
        let homepage: [String?]?
        let whitepaper: String?
        let blockchainSite: [String?]?
        let subredditURL: String?
        let twitterScreenName: String?
        let reposURL: RepoPayload?

        struct RepoPayload: Codable {
            let github: [String?]?

            enum CodingKeys: String, CodingKey {
                case github
            }
        }

        enum CodingKeys: String, CodingKey {
            case homepage
            case whitepaper
            case blockchainSite = "blockchain_site"
            case subredditURL = "subreddit_url"
            case twitterScreenName = "twitter_screen_name"
            case reposURL = "repos_url"
        }
    }

    struct MarketDataPayload: Codable {
        let currentPrice: [String: Double]?
        let marketCap: [String: Double]?
        let totalVolume: [String: Double]?
        let high24h: [String: Double]?
        let low24h: [String: Double]?
        let priceChangePercentage24h: Double?
        let priceChangePercentage7d: Double?
        let priceChangePercentage30d: Double?
        let circulatingSupply: Double?
        let totalSupply: Double?
        let maxSupply: Double?
        let ath: [String: Double]?
        let athDate: [String: String]?
        let atl: [String: Double]?
        let atlDate: [String: String]?

        enum CodingKeys: String, CodingKey {
            case currentPrice = "current_price"
            case marketCap = "market_cap"
            case totalVolume = "total_volume"
            case high24h = "high_24h"
            case low24h = "low_24h"
            case priceChangePercentage24h = "price_change_percentage_24h"
            case priceChangePercentage7d = "price_change_percentage_7d"
            case priceChangePercentage30d = "price_change_percentage_30d"
            case circulatingSupply = "circulating_supply"
            case totalSupply = "total_supply"
            case maxSupply = "max_supply"
            case ath
            case athDate = "ath_date"
            case atl
            case atlDate = "atl_date"
        }
    }

    struct CommunityDataPayload: Codable {
        let twitterFollowers: Int?
        let redditSubscribers: Int?

        enum CodingKeys: String, CodingKey {
            case twitterFollowers = "twitter_followers"
            case redditSubscribers = "reddit_subscribers"
        }
    }

    struct DeveloperDataPayload: Codable {
        let forks: Int?
        let stars: Int?
        let commitCount4Weeks: Int?

        enum CodingKeys: String, CodingKey {
            case forks
            case stars
            case commitCount4Weeks = "commit_count_4_weeks"
        }
    }

    let id: String
    let symbol: String
    let name: String
    let description: DescriptionPayload?
    let image: ImagePayload?
    let links: LinksPayload?
    let marketData: MarketDataPayload?
    let marketCapRank: Int?
    let communityData: CommunityDataPayload?
    let developerData: DeveloperDataPayload?

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case description
        case image
        case links
        case marketData = "market_data"
        case marketCapRank = "market_cap_rank"
        case communityData = "community_data"
        case developerData = "developer_data"
    }
}
