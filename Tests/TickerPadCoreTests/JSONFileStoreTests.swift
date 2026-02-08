import XCTest
@testable import TickerPadCore

final class JSONFileStoreTests: XCTestCase {
    func testSaveAndLoad() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let file = directory.appendingPathComponent("watchlist.json")
        let store = JSONFileStore<[WatchlistItem]>(url: file)
        let payload = [WatchlistItem(coinID: "bitcoin", sortOrder: 0, isPinned: true)]

        try store.save(payload)
        let loaded = try store.load()

        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.coinID, "bitcoin")
        XCTAssertEqual(loaded?.first?.isPinned, true)
    }
}
