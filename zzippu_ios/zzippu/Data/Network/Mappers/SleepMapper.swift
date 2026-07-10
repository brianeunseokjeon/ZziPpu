// Data/Network/Mappers/SleepMapper.swift
// SleepResponseDTO ↔ SleepRecord(Domain Entity)

import Foundation

enum SleepMapper {

    // MARK: - DTO → Entity

    static func toEntity(_ dto: SleepResponseDTO) -> SleepRecord {
        SleepRecord(
            id: dto.id,
            babyId: dto.babyId,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            durationMinutes: dto.durationMinutes,
            memo: dto.memo,
            createdAt: dto.createdAt
        )
    }

    // MARK: - Entity → Start Request DTO

    static func toStartRequest(_ sleep: SleepRecord) -> SleepStartRequestDTO {
        SleepStartRequestDTO(
            startedAt: sleep.startedAt,
            memo: sleep.memo
        )
    }

    // MARK: - End Request DTO

    static func toEndRequest(endedAt: Date) -> SleepEndRequestDTO {
        SleepEndRequestDTO(endedAt: endedAt)
    }
}
