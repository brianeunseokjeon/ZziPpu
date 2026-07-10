// Data/Network/DTOs/VaccinationDTO.swift
// 서버 VaccinationResponse / MarkAdministeredRequest 대응.
// is_overdue·days_until은 서버도 보내지만 iOS는 로컬 계산 → 디코딩하지 않음.

import Foundation

struct VaccinationResponseDTO: Decodable {
    let id: UUID
    let babyId: UUID
    let vaccineName: String
    let doseNumber: Int
    let scheduledDate: String          // date(YYYY-MM-DD)
    let administeredDate: String?      // date(YYYY-MM-DD)
    let hospitalName: String?
    let memo: String?
    let createdAt: Date                // datetime
}

struct MarkAdministeredRequestDTO: Encodable {
    let administeredDate: String       // YYYY-MM-DD
    let hospitalName: String?
}
