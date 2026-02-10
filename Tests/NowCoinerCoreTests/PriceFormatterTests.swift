import XCTest
@testable import NowCoinerCore

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

    func testCompactCurrencyWithFixedFractionDigitsPadsZeros() {
        let text = PriceFormatter.compactCurrency(0.09, code: "usd", fractionDigits: 5)
        XCTAssertEqual(text, "$0.09000")
    }

    func testCompactFractionDigitsFollowsCurrentCompactOutput() {
        XCTAssertEqual(PriceFormatter.compactFractionDigits(for: 0.09395), 5)
        XCTAssertEqual(PriceFormatter.compactFractionDigits(for: 0.09), 2)
        XCTAssertEqual(PriceFormatter.compactFractionDigits(for: 68922.56), 2)
    }
}
