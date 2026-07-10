// Data/Network/Mappers/VaccinationMapper.swift
// VaccinationResponseDTO ↔ Vaccination(Domain Entity).

import Foundation

enum VaccinationMapper {

    static func toEntity(_ dto: VaccinationResponseDTO) -> Vaccination {
        let scheduled = APIDateCodec.parseDate(dto.scheduledDate) ?? Date.now
        let administered = dto.administeredDate.flatMap { APIDateCodec.parseDate($0) }
        return Vaccination(
            id: dto.id,
            babyId: dto.babyId,
            vaccineName: dto.vaccineName,
            doseNumber: dto.doseNumber,
            scheduledDate: scheduled,
            administeredDate: administered,
            hospitalName: dto.hospitalName,
            memo: dto.memo,
            createdAt: dto.createdAt
        )
    }

    static func toMarkRequest(
        administeredDate: Date,
        hospitalName: String?
    ) -> MarkAdministeredRequestDTO {
        let trimmed = hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return MarkAdministeredRequestDTO(
            administeredDate: APIDateCodec.formatDate(administeredDate),
            hospitalName: (trimmed?.isEmpty ?? true) ? nil : trimmed
        )
    }
}
