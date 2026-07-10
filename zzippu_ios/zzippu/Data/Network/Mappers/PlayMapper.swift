// Data/Network/Mappers/PlayMapper.swift
// PlayResponseDTO ↔ PlayRecord(Domain Entity)

import Foundation

enum PlayMapper {

    // MARK: - DTO → Entity

    static func toEntity(_ dto: PlayResponseDTO) -> PlayRecord {
        PlayRecord(
            id: dto.id,
            babyId: dto.babyId,
            playType: PlayType(rawValue: dto.playType) ?? .freePlay,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            durationMinutes: dto.durationMinutes,
            memo: dto.memo,
            createdAt: dto.createdAt
        )
    }

    // MARK: - Entity → Create Request DTO

    static func toCreateRequest(_ play: PlayRecord) -> PlayCreateRequestDTO {
        PlayCreateRequestDTO(
            playType: play.playType.rawValue,
            startedAt: play.startedAt,
            endedAt: play.endedAt,
            durationMinutes: play.durationMinutes,
            memo: play.memo
        )
    }
}
