import Foundation

public struct JSONFileStore<Value: Codable & Sendable>: Sendable {
    private let url: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let encryptAtRest: Bool

    public init(
        url: URL,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        encryptAtRest: Bool = true
    ) {
        self.url = url
        self.encoder = encoder
        self.decoder = decoder
        self.encryptAtRest = encryptAtRest
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> Value? {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return nil
        }
        let rawData = try Data(contentsOf: url)
        let plaintext: Data

        if encryptAtRest, FileCrypto.isEncryptedPayload(rawData) {
            plaintext = try FileCrypto.decrypt(rawData)
        } else {
            plaintext = rawData
        }

        let decoded = try decoder.decode(Value.self, from: plaintext)

        // Best-effort migration from legacy plaintext files to encrypted payloads.
        if encryptAtRest, !FileCrypto.isEncryptedPayload(rawData) {
            try? save(decoded)
        }

        return decoded
    }

    public func save(_ value: Value) throws {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let plaintext = try encoder.encode(value)
        let payload = encryptAtRest ? try FileCrypto.encrypt(plaintext) : plaintext
        try payload.write(to: url, options: .atomic)
    }
}
