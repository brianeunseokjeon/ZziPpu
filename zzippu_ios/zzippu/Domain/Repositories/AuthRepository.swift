// Domain/Repositories/AuthRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol AuthRepository {
    /// OTP 발송 요청
    func requestEmailOtp(email: String) async throws
    /// OTP 검증 → AuthSession 반환 (accessToken Keychain 저장은 impl에서)
    func verifyEmailOtp(email: String, code: String) async throws -> AuthSession
    /// 약관 목록 조회
    func fetchTerms() async throws -> [TermDoc]
    /// 약관 동의 (Bearer 토큰 필요)
    func agreeTerms(_ agreements: [(type: TermType, version: String)]) async throws
    /// Keychain에서 세션 복원 (동기, 런타임 검증 없음)
    func currentSession() -> AuthSession?
    /// 마지막 로그인 이메일 (설정 화면 표시용, 비민감). 없으면 nil.
    func loginEmail() -> String?
    /// 로그아웃 (Keychain + UserDefaults 초기화)
    func signOut()

    /// 회원 탈퇴(서버 소프트삭제, 30일 유예). 유예 내 재로그인 시 자동 복구.
    func withdraw() async throws
    /// 공동양육자 코드 redeem (시그니처만 — 미구현 stub 허용)
    func redeemCode(_ code: String) async throws -> AuthSession
}
