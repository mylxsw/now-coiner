import Foundation
import CryptoKit
import Security

enum FileCrypto {
    private static let payloadMagic = Data("NCENC1".utf8)
    private static let keychainService = "ai.gulu.app.nowcoiner"
    private static let keychainAccount = "storage.masterkey.v1"

    static func isEncryptedPayload(_ data: Data) -> Bool {
        data.starts(with: payloadMagic)
    }

    static func encrypt(_ plaintext: Data) throws -> Data {
        let key = try loadOrCreateMasterKey()
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealedBox.combined else {
            throw CryptoError.invalidCiphertext
        }

        var payload = Data(capacity: payloadMagic.count + combined.count)
        payload.append(payloadMagic)
        payload.append(combined)
        return payload
    }

    static func decrypt(_ payload: Data) throws -> Data {
        guard isEncryptedPayload(payload) else {
            return payload
        }

        let key = try loadOrCreateMasterKey()
        let combined = payload.dropFirst(payloadMagic.count)
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(sealedBox, using: key)
    }

    private static func loadOrCreateMasterKey() throws -> SymmetricKey {
        do {
            if let existingData = try fetchKeyData() {
                return SymmetricKey(data: existingData)
            }

            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }

            var addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount,
                kSecValueData as String: keyData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
#if os(macOS)
            addQuery[kSecUseDataProtectionKeychain as String] = true
#endif

            let status = SecItemAdd(addQuery as CFDictionary, nil)
            if status == errSecSuccess {
                return key
            }

            if status == errSecDuplicateItem,
               let existingData = try fetchKeyData() {
                return SymmetricKey(data: existingData)
            }

            throw CryptoError.keychainFailure(status)
        } catch CryptoError.keychainFailure {
            // Some contexts (e.g. non-app test runners) cannot access keychain.
            // Fall back to an app-support key file so encrypted persistence still works.
            return try loadOrCreateFallbackFileKey()
        }
    }

    private static func fetchKeyData() throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
#if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
#endif

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw CryptoError.invalidKeyMaterial
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw CryptoError.keychainFailure(status)
        }
    }

    private static func loadOrCreateFallbackFileKey(fileManager: FileManager = .default) throws -> SymmetricKey {
        let keyURL = fallbackKeyURL(fileManager: fileManager)
        if fileManager.fileExists(atPath: keyURL.path) {
            let existing = try Data(contentsOf: keyURL)
            guard existing.count == 32 else {
                throw CryptoError.invalidKeyMaterial
            }
            return SymmetricKey(data: existing)
        }

        let generated = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let directory = keyURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try generated.write(to: keyURL, options: .atomic)
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: keyURL.path)
        return SymmetricKey(data: generated)
    }

    private static func fallbackKeyURL(fileManager: FileManager) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("NowCoiner", isDirectory: true)
        return directory.appendingPathComponent(".storage_masterkey_v1")
    }
}

enum CryptoError: Error, Equatable {
    case invalidCiphertext
    case invalidKeyMaterial
    case keychainFailure(OSStatus)
}
