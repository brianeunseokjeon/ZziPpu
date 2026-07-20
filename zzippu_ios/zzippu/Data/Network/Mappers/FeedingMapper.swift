// Data/Network/Mappers/FeedingMapper.swift
// FeedingResponseDTO ↔ Feeding(Domain Entity)

import Foundation

enum FeedingMapper {

    // MARK: - DTO → Entity

    static func toEntity(_ dto: FeedingResponseDTO) -> Feeding {
        let type = FeedingType(rawValue: dto.feedingType) ?? .formula
        return Feeding(
            id: dto.id,
            babyId: dto.babyId,
            type: type,
            amountMl: dto.amountMl,
            durationMinutes: dto.durationMinutes,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            memo: dto.memo,
            didVomit: dto.didVomit ?? false,
            createdAt: dto.createdAt
        )
    }

    // MARK: - Entity → Create Request DTO

    static func toCreateRequest(_ feeding: Feeding) -> FeedingCreateRequestDTO {
        FeedingCreateRequestDTO(
            feedingType: feeding.type.rawValue,
            startedAt: feeding.startedAt,
            endedAt: feeding.endedAt,
            amountMl: feeding.amountMl,
            durationMinutes: feeding.durationMinutes,
            memo: feeding.memo,
            didVomit: feeding.didVomit
        )
    }

    // MARK: - Entity → Update Request DTO

    static func toUpdateRequest(_ feeding: Feeding) -> FeedingUpdateRequestDTO {
        FeedingUpdateRequestDTO(
            feedingType: feeding.type.rawValue,
            startedAt: feeding.startedAt,
            endedAt: feeding.endedAt,
            amountMl: feeding.amountMl,
            durationMinutes: feeding.durationMinutes,
            memo: feeding.memo,
            didVomit: feeding.didVomit
        )
    }
}
