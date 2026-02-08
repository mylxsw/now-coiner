import XCTest
@testable import TickerPadCore

final class ExchangeURLBuilderTests: XCTestCase {
    func testTradingViewURL() {
        let url = ExchangeURLBuilder.tradingView(symbol: "btc", exchange: .binance)
        XCTAssertEqual(url?.absoluteString, "https://www.tradingview.com/chart/?symbol=BINANCE:BTCUSDT")
    }

    func testExchangeURLForCoinbase() {
        let url = ExchangeURLBuilder.exchange(symbol: "btc", coinID: "bitcoin", exchange: .coinbase)
        XCTAssertEqual(url?.absoluteString, "https://www.coinbase.com/price/bitcoin")
    }
}
