import XCTest
@testable import TickerPadCore

final class PriceFormatterTests: XCTestCase {
    func testMenuBarTextFullStyle() {
        let text = PriceFormatter.menuBarText(
            symbol: "btc",
            price: 16903.83,
            changePercent: 1.68,
            currencyCode: "usd",
            style: .full
        )

        XCTAssertTrue(text.contains("BTC"))
        XCTAssertTrue(text.contains("▲ 1.68%"))
    }

    func testPercentFormattingWithNegativeValue() {
        XCTAssertEqual(PriceFormatter.percent(-2.5), "▼ 2.50%")
    }
}
