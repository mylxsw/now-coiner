import XCTest
@testable import NowCoinerCore

final class URLSafetyTests: XCTestCase {
    func testExternalURLRequiresHTTPS() {
        XCTAssertNil(URLSafety.validatedExternalWebURL(from: "http://example.com"))
        XCTAssertNil(URLSafety.validatedExternalWebURL(from: "file:///tmp/test"))
        XCTAssertNotNil(URLSafety.validatedExternalWebURL(from: "https://example.com"))
    }

    func testIconURLRequiresCoinGeckoHost() {
        XCTAssertNotNil(URLSafety.validatedIconURL(from: "https://assets.coingecko.com/test.png"))
        XCTAssertNotNil(URLSafety.validatedIconURL(from: "https://coin-images.coingecko.com/test.png"))
        XCTAssertNil(URLSafety.validatedIconURL(from: "https://example.com/test.png"))
    }
}
