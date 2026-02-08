import XCTest
@testable import TickerPadCore

final class ExponentialBackoffTests: XCTestCase {
    func testBackoffGrowthAndCap() {
        let backoff = ExponentialBackoff(baseDelay: 1, maxDelay: 60)
        XCTAssertEqual(backoff.delay(for: 1), 1)
        XCTAssertEqual(backoff.delay(for: 2), 2)
        XCTAssertEqual(backoff.delay(for: 6), 32)
        XCTAssertEqual(backoff.delay(for: 10), 60)
    }
}
