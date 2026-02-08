import XCTest
@testable import TickerPadCore

final class SearchFilterTests: XCTestCase {
    func testFilterBySymbolAndName() {
        let coins = [
            Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin"),
            Coin(id: "ethereum", symbol: "eth", name: "Ethereum")
        ]

        XCTAssertEqual(SearchFilter.filter(coins: coins, query: "bit").map(\.id), ["bitcoin"])
        XCTAssertEqual(SearchFilter.filter(coins: coins, query: "eth").map(\.id), ["ethereum"])
    }
}
