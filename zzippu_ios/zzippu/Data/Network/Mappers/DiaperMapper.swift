// Data/Network/Mappers/DiaperMapper.swift
// DiaperResponseDTO ↔ DiaperRecord(Domain Entity)

import Foundation

enum DiaperMapper {

    // MARK: - DTO → Entity

    static func toEntity(_ dto: DiaperResponseDTO) -> DiaperRecord {
        DiaperRecord(
            id: dto.id,
            babyId: dto.babyId,
            recordedAt: dto.recordedAt,
            diaperType: DiaperType(rawValue: dto.diaperType) ?? .pee,
            stoolColor: dto.stoolColor.flatMap { StoolColor(rawValue: $0) },
            stoolState: dto.stoolState.flatMap { StoolState(rawValue: $0) },
            amount: dto.amount.flatMap { DiaperAmount(rawValue: $0) },
            memo: dto.memo,
            createdAt: dto.createdAt
        )
    }

    // MARK: - Entity → Create Request DTO

    static func toCreateRequest(_ diaper: DiaperRecord) -> DiaperCreateRequestDTO {
        DiaperCreateRequestDTO(
            recordedAt: diaper.recordedAt,
            diaperType: diaper.diaperType.rawValue,
            stoolColor: diaper.stoolColor?.rawValue,
            stoolState: diaper.stoolState?.rawValue,
            amount: diaper.amount?.rawValue,
            memo: diaper.memo
        )
    }
}
