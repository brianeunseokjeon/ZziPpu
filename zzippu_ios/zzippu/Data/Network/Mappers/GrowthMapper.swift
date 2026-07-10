// Data/Network/Mappers/GrowthMapper.swift
// GrowthResponseDTO ↔ GrowthRecord(Domain Entity)

import Foundation

enum GrowthMapper {

    // MARK: - DTO → Entity

    static func toEntity(_ dto: GrowthResponseDTO) -> GrowthRecord {
        let recordedAt = APIDateCodec.parseDate(dto.recordedAt) ?? Date.now
        return GrowthRecord(
            id: dto.id,
            babyId: dto.babyId,
            recordedAt: recordedAt,
            weightG: dto.weightG,
            heightCm: dto.heightCm,
            headCircumferenceCm: dto.headCircumferenceCm,
            memo: dto.memo,
            createdAt: dto.createdAt
        )
    }

    // MARK: - Entity → Create Request DTO

    static func toCreateRequest(_ record: GrowthRecord) -> GrowthCreateRequestDTO {
        GrowthCreateRequestDTO(
            recordedAt: APIDateCodec.formatDate(record.recordedAt),
            weightG: record.weightG,
            heightCm: record.heightCm,
            headCircumferenceCm: record.headCircumferenceCm,
            memo: record.memo
        )
    }
}
