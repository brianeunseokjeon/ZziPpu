// Data/Network/Mappers/CareLogMapper.swift
// CareLogResponseDTO ↔ CareLog(Domain Entity)

import Foundation

enum CareLogMapper {

    // MARK: - DTO → Entity

    static func toEntity(_ dto: CareLogResponseDTO) -> CareLog {
        CareLog(
            id: dto.id,
            babyId: dto.babyId,
            category: CareCategory(rawValue: dto.category) ?? .bath,
            name: dto.name,
            dose: dto.dose,
            recordedAt: dto.recordedAt,
            memo: dto.memo,
            createdAt: dto.createdAt
        )
    }

    // MARK: - Entity → Create Request DTO

    static func toCreateRequest(_ log: CareLog) -> CareLogCreateRequestDTO {
        CareLogCreateRequestDTO(
            category: log.category.rawValue,
            name: log.name,
            dose: log.dose,
            recordedAt: log.recordedAt,
            memo: log.memo
        )
    }

    // MARK: - Entity → Update Request DTO

    static func toUpdateRequest(_ log: CareLog) -> CareLogUpdateRequestDTO {
        CareLogUpdateRequestDTO(
            name: log.name,
            dose: log.dose,
            recordedAt: log.recordedAt,
            memo: log.memo
        )
    }
}
