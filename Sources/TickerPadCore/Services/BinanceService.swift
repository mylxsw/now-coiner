import Foundation

public struct BinanceService: BinanceServicing {
    private let client: HTTPClient
    private let baseURL: URL

    public init(
        client: HTTPClient = URLSessionHTTPClient(),
        baseURL: URL = URL(string: "https://api.binance.com")!
    ) {
        self.client = client
        self.baseURL = baseURL
    }

    public func fetchTickerPrices(symbols: [String]) async throws -> [String: Double] {
        guard !symbols.isEmpty else { return [:] }

        var components = URLComponents(url: baseURL.appending(path: "/api/v3/ticker/price"), resolvingAgainstBaseURL: false)
        if symbols.count == 1 {
            components?.queryItems = [URLQueryItem(name: "symbol", value: symbols[0].uppercased())]
        } else {
            let json = symbols.map { "\"\($0.uppercased())\"" }.joined(separator: ",")
            components?.queryItems = [URLQueryItem(name: "symbols", value: "[\(json)]")]
        }

        guard let url = components?.url else { throw NetworkError.invalidURL }

        let request = URLRequest(url: url)
        let (data, response) = try await client.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw NetworkError.statusCode(response.statusCode)
        }

        if symbols.count == 1 {
            let dto = try JSONDecoder().decode(TickerDTO.self, from: data)
            return [dto.symbol: Double(dto.price) ?? 0]
        }

        let items = try JSONDecoder().decode([TickerDTO].self, from: data)
        return items.reduce(into: [String: Double]()) { partial, item in
            partial[item.symbol] = Double(item.price) ?? 0
        }
    }
}

private struct TickerDTO: Codable {
    let symbol: String
    let price: String
}
