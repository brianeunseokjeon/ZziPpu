// Feature/Settings/SettingsViewModel.swift
// 설정 탭 루트 VM — 활성 아기 헤더, 계정 정보, 로그아웃, 내보내기 URL.
// Domain 프로토콜만 의존. 로그아웃은 authRepository.signOut + onSignedOut 콜백(세션 무효화).

import Foundation
import Observation

@Observable
final class SettingsViewModel {

    // MARK: - State

    var baby: Baby?
    var isLoading: Bool = false
    var errorMessage: String?

    // 현재 몸무게(성장기록 최신값) — 표시/프리필용.
    var latestWeightG: Int?
    var currentWeightKgText: String = ""
    var isSavingWeight: Bool = false

    // MARK: - Dependencies

    private let babyRepository: BabyRepository
    private let authRepository: AuthRepository
    private let growthRepository: GrowthRepository
    private let babyId: UUID

    /// 로그아웃 실행 시 라우팅 무효화(SessionState.setSession(nil)) 콜백
    var onSignedOut: (() -> Void)?

    init(
        babyRepository: BabyRepository,
        authRepository: AuthRepository,
        growthRepository: GrowthRepository,
        babyId: UUID
    ) {
        self.babyRepository = babyRepository
        self.authRepository = authRepository
        self.growthRepository = growthRepository
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
        guard let s = baby?.photoUrl, !s.isEmpty else { return nil }
        return URL(string: s)
    }

    // MARK: - Current Weight (성장기록 최신)

    /// 최신 체중 표기(예: "3.5 kg"). 없으면 "미등록".
    var latestWeightText: String {
        guard let g = latestWeightG, g > 0 else { return "미등록" }
        let kg = Double(g) / 1000.0
        return String(format: "%.2f kg", kg)
    }

    /// 입력 검증(0~15 kg). 정상/빈 값이면 nil.
    var currentWeightValidation: String? {
        let text = currentWeightKgText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        guard let kg = Double(text) else { return "숫자로 입력해 주세요 (예: 3.5)" }
        guard (0...15).contains(kg) else { return "0~15 kg 범위로 입력해 주세요." }
        return nil
    }

    var canSaveWeight: Bool {
        let text = currentWeightKgText.trimmingCharacters(in: .whitespaces)
        return !text.isEmpty && currentWeightValidation == nil && !isSavingWeight
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
            // 최신 체중은 실패해도 화면 진입 막지 않음(부가 정보).
            let series = (try? await growthRepository.series(babyId: babyId)) ?? []
            self.latestWeightG = series
                .filter { ($0.weightG ?? 0) > 0 }
                .max(by: { $0.recordedAt < $1.recordedAt })?
                .weightG
        }
    }

    /// 현재 몸무게 저장 = 오늘 날짜 성장기록 1건 생성(kg→g). 성공 시 true.
    /// 시간에 따라 변하는 값이라 Baby가 아닌 GrowthRecord에 적재(과거 이력·추세 보존).
    @MainActor
    func saveCurrentWeight() async -> Bool {
        guard canSaveWeight,
              let kg = Double(currentWeightKgText.trimmingCharacters(in: .whitespaces))
        else { return false }
        isSavingWeight = true
        defer { isSavingWeight = false }
        let weightG = Int(kg * 1000)
        let record = GrowthRecord.new(babyId: babyId, recordedAt: .now, weightG: weightG)
        do {
            let saved = try await growthRepository.create(record)
            latestWeightG = saved.weightG
            currentWeightKgText = ""
            return true
        } catch {
            errorMessage = "몸무게 저장에 실패했어요. 다시 시도해 주세요."
            return false
        }
    }

    /// 프로필 편집 후 낙관적 반영용 — 편집 화면에서 저장한 Baby를 주입.
    func applyUpdatedBaby(_ updated: Baby) {
        self.baby = updated
    }

    /// 명시적 로그아웃: 토큰 폐기 → 세션 무효화(로그인 화면 전환).
    func signOut() {
        authRepository.signOut()
        onSignedOut?()
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
