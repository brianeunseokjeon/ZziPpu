// Feature/Settings/SettingsViewModel.swift
// 설정 탭 루트 VM — 활성 아기 헤더, 계정 정보, 로그아웃, 내보내기 URL.
// Domain 프로토콜만 의존. 로그아웃은 authRepository.signOut + onSignedOut 콜백(세션 무효화).

import Foundation
import Observation
import UIKit

@Observable
final class SettingsViewModel {

    // MARK: - State

    var baby: Baby?
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let babyRepository: BabyRepository
    private let authRepository: AuthRepository
    private let babyId: UUID

    /// 로그아웃 실행 시 라우팅 무효화(SessionState.setSession(nil)) 콜백
    /// 로그아웃 실행(상위에서 AppContainer.performLogout 주입). async — push 완료 후 세션 종료.
    var onLogout: (() async -> Void)?

    /// 회원 탈퇴 실행(상위에서 AppContainer.withdrawAccount 주입).
    var onWithdraw: (() async throws -> Void)?
    var isWithdrawing: Bool = false
    var withdrawError: String?

    init(
        babyRepository: BabyRepository,
        authRepository: AuthRepository,
        babyId: UUID
    ) {
        self.babyRepository = babyRepository
        self.authRepository = authRepository
        self.babyId = babyId
    }

    // MARK: - Derived (계정 정보 — 민감정보 미노출)

    var loginEmail: String? { authRepository.loginEmail() }

    var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    /// 나이 표기 (예: "생후 42일 · 1개월")
    var ageText: String? {
        guard let baby else { return nil }
        let days = Self.ageDays(birthDate: baby.birthDate)
        let months = days / 30
        return months >= 1 ? "생후 \(days)일 · \(months)개월" : "생후 \(days)일"
    }

    var avatarGender: BabyGender {
        switch baby?.gender {
        case .male:   return .male
        case .female: return .female
        default:      return .unknown
        }
    }

    var photoURL: URL? {
        guard let s = baby?.photoUrl, !s.isEmpty,
              let url = URL(string: s),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return nil }
        return url
    }

    /// 기기-로컬 대표 이미지(있으면 아바타 최우선). 서버 미업로드.
    var localImage: UIImage? {
        LocalBabyImageStore.shared.loadImage(for: babyId)
    }

    // MARK: - Export

    /// 데이터 내보내기 URL (인증 헤더가 없어 브라우저 다운로드는 서버 인증 정책에 의존).
    /// MVP: ShareSheet로 링크 공유. format = json|csv.
    func exportURL(format: String) -> URL? {
        AuthConfig.baseURL.appendingPathComponent(
            "/api/v1/babies/\(babyId.uuidString)/export"
        ).appending(queryItems: [URLQueryItem(name: "format", value: format)])
    }

    // MARK: - Actions

    func load() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                self.baby = try await babyRepository.fetch(id: babyId)
                self.errorMessage = nil
            } catch {
                self.errorMessage = "프로필을 불러오지 못했어요"
            }
        }
    }

    /// 프로필 편집 후 낙관적 반영용 — 편집 화면에서 저장한 Baby를 주입.
    func applyUpdatedBaby(_ updated: Baby) {
        self.baby = updated
    }

    /// 명시적 로그아웃: 미동기화 push → 토큰 폐기 → 로컬 삭제 → 세션 무효화.
    /// 실제 순서는 상위(AppContainer.performLogout)에서 보장(토큰 유효 상태에서 push 먼저).
    func signOut() {
        Task { @MainActor in await onLogout?() }
    }

    /// 회원 탈퇴: 서버 소프트삭제 요청 → 성공 시 로컬 정리 + 로그인 화면. 실패 시 에러 표시.
    func withdraw() {
        guard !isWithdrawing else { return }
        isWithdrawing = true
        Task { @MainActor in
            defer { isWithdrawing = false }
            do {
                try await onWithdraw?()
            } catch {
                withdrawError = "탈퇴에 실패했어요. 잠시 후 다시 시도해 주세요."
            }
        }
    }

    // MARK: - Helpers

    /// 한국식 생후 일수: 생일 당일 = 1.
    static func ageDays(birthDate: Date, now: Date = .now) -> Int {
        let cal = Calendar.kst
        let birth = cal.startOfDay(for: birthDate)
        let today = cal.startOfDay(for: now)
        let diff = cal.dateComponents([.day], from: birth, to: today).day ?? 0
        return max(0, diff) + 1
    }
}
