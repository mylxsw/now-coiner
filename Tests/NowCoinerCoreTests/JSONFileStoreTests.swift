import XCTest
@testable import NowCoinerCore

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

        let raw = try Data(contentsOf: file)
        XCTAssertTrue(FileCrypto.isEncryptedPayload(raw))
        XCTAssertFalse(String(decoding: raw, as: UTF8.self).contains("bitcoin"))
    }

    func testLoadMigratesPlaintextFileToEncrypted() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let file = directory.appendingPathComponent("watchlist.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let payload = [WatchlistItem(coinID: "ethereum", sortOrder: 0, isPinned: false)]
        let plaintext = try encoder.encode(payload)
        try plaintext.write(to: file, options: .atomic)

        let store = JSONFileStore<[WatchlistItem]>(url: file)
        let loaded = try store.load()

        XCTAssertEqual(loaded?.first?.coinID, "ethereum")

        let migrated = try Data(contentsOf: file)
        XCTAssertTrue(FileCrypto.isEncryptedPayload(migrated))
    }
}
