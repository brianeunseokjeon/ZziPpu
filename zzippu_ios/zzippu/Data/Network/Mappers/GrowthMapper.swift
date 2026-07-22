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
            temperatureC: dto.temperatureC,
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
            temperatureC: record.temperatureC,
            memo: record.memo
        )
    }

    // MARK: - Entity → Update Request DTO (PATCH — 전체교체)

    static func toUpdateRequest(_ record: GrowthRecord) -> GrowthUpdateRequestDTO {
        GrowthUpdateRequestDTO(
            recordedAt: APIDateCodec.formatDate(record.recordedAt),   // YYYY-MM-DD(백엔드 date)
            weightG: record.weightG,
            heightCm: record.heightCm,
            headCircumferenceCm: record.headCircumferenceCm,
            temperatureC: record.temperatureC,
            memo: record.memo
        )
    }
}
