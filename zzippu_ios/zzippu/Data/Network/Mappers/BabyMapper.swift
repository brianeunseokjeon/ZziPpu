// Data/Network/Mappers/BabyMapper.swift
// BabyResponseDTO ↔ Baby(Domain Entity)

import Foundation

enum BabyMapper {

    // MARK: - DTO → Entity

    static func toEntity(_ dto: BabyResponseDTO) -> Baby {
        let birthDate = APIDateCodec.parseDate(dto.birthDate) ?? Date.now
        let gender: Gender = dto.gender.flatMap { Gender(rawValue: $0) } ?? .unknown

        return Baby(
            id: dto.id,
            userId: dto.userId,
            name: dto.name,
            birthDate: birthDate,
            gender: gender,
            birthWeightG: dto.birthWeightG,
            photoUrl: dto.photoUrl,
            createdAt: dto.createdAt
        )
    }

    // MARK: - Entity → Create Request DTO

    static func toCreateRequest(_ baby: Baby) -> BabyCreateRequestDTO {
        BabyCreateRequestDTO(
            name: baby.name,
            birthDate: APIDateCodec.formatDate(baby.birthDate),
            gender: baby.gender == .unknown ? nil : baby.gender.rawValue,
            birthWeightG: baby.birthWeightG
        )
    }

    // MARK: - Entity → Update Request DTO

    static func toUpdateRequest(_ baby: Baby) -> BabyUpdateRequestDTO {
        BabyUpdateRequestDTO(
            name: baby.name,
            birthDate: APIDateCodec.formatDate(baby.birthDate),
            gender: baby.gender == .unknown ? nil : baby.gender.rawValue,
            birthWeightG: baby.birthWeightG,
            photoUrl: baby.photoUrl
        )
    }
}
