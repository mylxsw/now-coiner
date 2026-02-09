import XCTest
@testable import NowCoinerCore

final class WebSocketMessageParserTests: XCTestCase {
    func testParsesCombinedPayload() {
        let json = """
        {"stream":"btcusdt@miniTicker","data":{"s":"BTCUSDT","c":"97150.23"}}
        """
        let data = Data(json.utf8)

        let tick = WebSocketMessageParser.parseTick(from: data)

        XCTAssertEqual(tick?.symbol, "BTCUSDT")
        XCTAssertEqual(tick?.currentPrice, 97150.23)
    }

    func testParsesDirectPayload() {
        let json = """
        {"s":"ETHUSDT","c":"3250.45"}
        """
        let data = Data(json.utf8)

        let tick = WebSocketMessageParser.parseTick(from: data)

        XCTAssertEqual(tick?.symbol, "ETHUSDT")
        XCTAssertEqual(tick?.currentPrice, 3250.45)
    }
}
