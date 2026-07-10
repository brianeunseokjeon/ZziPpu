// Domain/Repositories/CaregiverRepository.swift
// 공동양육 초대/멤버 조회. 합류(joinByCode)는 BabyRepository에 이미 존재.
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol CaregiverRepository {
    /// 초대코드 발급 (POST /babies/{id}/caregivers/invite)
    func createInvite(babyId: UUID) async throws -> CaregiverInvite
    /// 멤버 목록 조회 (GET /babies/{id}/caregivers)
    func listMembers(babyId: UUID) async throws -> [CaregiverMember]
}
