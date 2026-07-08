// Data/Auth/KeychainTokenStore.swift
// accessToken을 iOS Keychain에 안전하게 저장/복원/삭제
// Security 프레임워크는 Data 레이어에서만 사용 — Domain은 모름

import Foundation
import Security

final class KeychainTokenStore {
    private let service = "jstyle.com.zzippu"
    private let accountKey = "accessToken"

    // MARK: - Save

    func save(token: String) throws {
        let data = Data(token.utf8)

        // 기존 항목 삭제 후 재삽입(업데이트 패턴)
        delete()

        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     accountKey,
            kSecValueData:       data,
            kSecAttrAccessible:  kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: - Load

    func load() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: accountKey,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else { return nil }
        return token
    }

    // MARK: - Delete

    @discardableResult
    func delete() -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: accountKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Error

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain 저장 실패 (OSStatus: \(status))"
        }
    }
}
