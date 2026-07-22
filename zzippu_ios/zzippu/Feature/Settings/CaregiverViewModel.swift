// Feature/Settings/CaregiverViewModel.swift
// 공동양육 VM — 초대코드 발급/멤버 목록(CaregiverRepository) + 코드 합류(BabyRepository.joinByCode).
// Domain 프로토콜만 의존.

import Foundation
import Observation

@Observable
final class CaregiverViewModel {

    // MARK: - State

    var members: [CaregiverMember] = []
    var invite: CaregiverInvite?
    var isLoadingMembers: Bool = false
    var isCreatingInvite: Bool = false
    var errorMessage: String?

    // 합류(코드 입력)
    var joinCode: String = ""
    var isJoining: Bool = false
    var joinError: String?

    // MARK: - Dependencies

    private let caregiverRepository: CaregiverRepository
    private let babyRepository: BabyRepository
    private let babyId: UUID

    /// 합류 성공 시 새로 연결된 아기 전달 (상위에서 활성 아기 갱신 가능)
    var onJoined: ((Baby) -> Void)?

    init(
        caregiverRepository: CaregiverRepository,
        babyRepository: BabyRepository,
        babyId: UUID
    ) {
        self.caregiverRepository = caregiverRepository
        self.babyRepository = babyRepository
        self.babyId = babyId
    }

    // MARK: - Derived

    /// 공유용 문자열 (코드 + 만료 안내)
    var shareText: String? {
        guard let invite else { return nil }
        return "먹놀잠 공동양육 초대코드: \(invite.code)\n(\(expiryText(invite.expiresAt)) 만료)"
    }

    func expiryText(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.timeZone = .kst
        fmt.setLocalizedDateFormatFromTemplate("MMMMdjmm")   // 기기 언어
        return fmt.string(from: date)
    }

    // MARK: - Actions

    func loadMembers() {
        isLoadingMembers = true
        Task { @MainActor in
            defer { isLoadingMembers = false }
            do {
                self.members = try await caregiverRepository.listMembers(babyId: babyId)
                self.errorMessage = nil
            } catch {
                // 멤버 목록은 부가 정보 — 실패해도 초대 기능은 유지
                self.errorMessage = "멤버 목록을 불러오지 못했어요"
            }
        }
    }

    func createInvite() {
        isCreatingInvite = true
        Task { @MainActor in
            defer { isCreatingInvite = false }
            do {
                self.invite = try await caregiverRepository.createInvite(babyId: babyId)
                self.errorMessage = nil
            } catch {
                self.errorMessage = "초대코드 발급에 실패했어요"
            }
        }
    }

    func join() {
        let code = joinCode.trimmingCharacters(in: .whitespaces)
        guard code.count >= 4 else {
            joinError = "코드를 정확히 입력해 주세요."
            return
        }
        isJoining = true
        Task { @MainActor in
            defer { isJoining = false }
            do {
                let baby = try await babyRepository.joinByCode(code)
                self.joinError = nil
                self.joinCode = ""
                onJoined?(baby)
                loadMembers()
            } catch {
                self.joinError = "합류에 실패했어요. 코드를 확인해 주세요."
            }
        }
    }
}
