// Data/Auth/AuthRepositoryImpl.swift
// AuthRepository 프로토콜 구현 — RemoteDataSource + KeychainTokenStore 조합

import Foundation

final class AuthRepositoryImpl: AuthRepository {

    private let remote: AuthRemoteDataSource
    private let tokenStore: KeychainTokenStore

    // UserDefaults 키 (비민감 플래그)
    private enum UDKey {
        static let userId         = "zzippu.userId"
        static let isNewUser      = "zzippu.isNewUser"
        static let termsRequired  = "zzippu.termsRequired"
        static let loginEmail     = "zzippu.loginEmail"
    }

    init(remote: AuthRemoteDataSource, tokenStore: KeychainTokenStore) {
        self.remote = remote
        self.tokenStore = tokenStore
    }

    // MARK: - OTP

    func requestEmailOtp(email: String) async throws {
        try await remote.requestEmailOtp(email: email)
    }

    func verifyEmailOtp(email: String, code: String) async throws -> AuthSession {
        let dto = try await remote.verifyEmailOtp(email: email, code: code)
        let session = AuthSession(
            accessToken: dto.accessToken,
            userId: dto.userId,
            isNewUser: dto.isNewUser,
            termsRequired: dto.termsRequired
        )
        // 토큰 저장 — Keychain (민감)
        try tokenStore.save(token: session.accessToken)
        // 비민감 플래그 — UserDefaults
        let ud = UserDefaults.standard
        ud.set(session.userId.uuidString, forKey: UDKey.userId)
        ud.set(session.isNewUser,         forKey: UDKey.isNewUser)
        ud.set(session.termsRequired,     forKey: UDKey.termsRequired)
        ud.set(email,                     forKey: UDKey.loginEmail)   // 설정 표시용(비민감)
        return session
    }

    // MARK: - Terms

    func fetchTerms() async throws -> [TermDoc] {
        let dtos = try await remote.fetchTerms()
        return dtos.compactMap { dto -> TermDoc? in
            guard let termType = TermType(rawValue: dto.type) else { return nil }
            return TermDoc(
                type: termType,
                version: dto.version,
                title: dto.title,
                content: dto.content,
                required: dto.required
            )
        }
    }

    func agreeTerms(_ agreements: [(type: TermType, version: String)]) async throws {
        guard let token = tokenStore.load() else {
            throw DomainError.unauthorized
        }
        let dtos = agreements.map { AgreementDTO(type: $0.type.rawValue, version: $0.version) }
        try await remote.agreeTerms(agreements: dtos, token: token)

        // 약관 동의 완료 → termsRequired = false
        UserDefaults.standard.set(false, forKey: UDKey.termsRequired)
    }

    // MARK: - Session Restore (Keychain 복원, 서버 검증 없음)

    func currentSession() -> AuthSession? {
        guard let token = tokenStore.load(),
              let userIdStr = UserDefaults.standard.string(forKey: UDKey.userId),
              let userId = UUID(uuidString: userIdStr)
        else { return nil }

        return AuthSession(
            accessToken: token,
            userId: userId,
            isNewUser: UserDefaults.standard.bool(forKey: UDKey.isNewUser),
            termsRequired: UserDefaults.standard.bool(forKey: UDKey.termsRequired)
        )
    }

    func loginEmail() -> String? {
        UserDefaults.standard.string(forKey: UDKey.loginEmail)
    }

    // MARK: - Sign Out

    func signOut() {
        tokenStore.delete()
        let ud = UserDefaults.standard
        ud.removeObject(forKey: UDKey.userId)
        ud.removeObject(forKey: UDKey.isNewUser)
        ud.removeObject(forKey: UDKey.termsRequired)
        ud.removeObject(forKey: UDKey.loginEmail)
    }

    // MARK: - Redeem Code (공동양육자 — stub)

    func redeemCode(_ code: String) async throws -> AuthSession {
        let dto = try await remote.redeemCode(code)
        let session = AuthSession(
            accessToken: dto.accessToken,
            userId: dto.userId,
            isNewUser: dto.isNewUser,
            termsRequired: dto.termsRequired
        )
        try tokenStore.save(token: session.accessToken)
        let ud = UserDefaults.standard
        ud.set(session.userId.uuidString, forKey: UDKey.userId)
        ud.set(session.isNewUser,         forKey: UDKey.isNewUser)
        ud.set(session.termsRequired,     forKey: UDKey.termsRequired)
        return session
    }
}
