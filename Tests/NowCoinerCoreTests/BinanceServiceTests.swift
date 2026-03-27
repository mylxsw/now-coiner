import XCTest
@testable import NowCoinerCore

final class BinanceServiceTests: XCTestCase {
    func testSingleSymbolThrowsWhenPriceInvalid() async throws {
        let payload = #"{"symbol":"BTCUSDT","price":"bad"}"#
        let client = MockHTTPClient(responseBody: Data(payload.utf8), statusCode: 200)
        let service = BinanceService(client: client, baseURL: URL(string: "https://api.binance.com")!)

        do {
            _ = try await service.fetchTickerPrices(symbols: ["BTCUSDT"])
            XCTFail("Expected invalid payload to throw")
        } catch let error as NetworkError {
            guard case .decoding = error else {
                XCTFail("Expected decoding error, got \(error)")
                return
            }
        }
    }

    func testMultiSymbolSkipsInvalidRows() async throws {
        let payload = #"""
        [
          {"symbol":"BTCUSDT","price":"100.5"},
          {"symbol":"ETHUSDT","price":"oops"}
        ]
        """#
        let client = MockHTTPClient(responseBody: Data(payload.utf8), statusCode: 200)
        let service = BinanceService(client: client, baseURL: URL(string: "https://api.binance.com")!)

        let result = try await service.fetchTickerPrices(symbols: ["BTCUSDT", "ETHUSDT"])

        XCTAssertEqual(result["BTCUSDT"], 100.5)
        XCTAssertNil(result["ETHUSDT"])
    }
}

private struct MockHTTPClient: HTTPClient {
    let responseBody: Data
    let statusCode: Int

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseBody, response)
    }
}
