// Data/Network/Mappers/BabyMapper.swift
// BabyResponseDTO ↔ Baby(Domain Entity)

import Foundation

enum BabyMapper {

    // MARK: - DTO → Entity

    static func toEntity(_ dto: BabyResponseDTO) -> Baby {
        // birth_date(KST 자정) + birth_time("HH:mm")를 합쳐 birthDate로 복원.
        // birth_time 없으면 자정(기존 동작) 유지 — 하위호환.
        let baseDate = APIDateCodec.parseDate(dto.birthDate) ?? Date.now
        let birthDate = APIDateCodec.combine(date: baseDate, time: dto.birthTime)
        let gender: Gender = dto.gender.flatMap { Gender(rawValue: $0) } ?? .unknown

        return Baby(
            id: dto.id,
            userId: dto.userId,
            name: dto.name,
            birthDate: birthDate,
            gender: gender,
            birthWeightG: dto.birthWeightG,
            birthHeightCm: dto.birthHeightCm,
            birthHeadCircumferenceCm: dto.birthHeadCircumferenceCm,
            birthChestCircumferenceCm: dto.birthChestCircumferenceCm,
            bloodType: dto.bloodType.flatMap { BloodType(rawValue: $0) },
            rhFactor: dto.rhFactor.flatMap { RhFactor(rawValue: $0) },
            photoUrl: dto.photoUrl,
            createdAt: dto.createdAt
        )
    }

    // MARK: - Entity → Create Request DTO

    static func toCreateRequest(_ baby: Baby) -> BabyCreateRequestDTO {
        BabyCreateRequestDTO(
            name: baby.name,
            birthDate: APIDateCodec.formatDate(baby.birthDate),
            birthTime: APIDateCodec.formatTime(baby.birthDate),
            gender: baby.gender == .unknown ? nil : baby.gender.rawValue,
            birthWeightG: baby.birthWeightG,
            birthHeightCm: baby.birthHeightCm,
            birthHeadCircumferenceCm: baby.birthHeadCircumferenceCm,
            birthChestCircumferenceCm: baby.birthChestCircumferenceCm,
            bloodType: baby.bloodType?.rawValue,
            rhFactor: baby.rhFactor?.rawValue
        )
    }

    // MARK: - Entity → Update Request DTO

    static func toUpdateRequest(_ baby: Baby) -> BabyUpdateRequestDTO {
        BabyUpdateRequestDTO(
            name: baby.name,
            birthDate: APIDateCodec.formatDate(baby.birthDate),
            birthTime: APIDateCodec.formatTime(baby.birthDate),
            gender: baby.gender == .unknown ? nil : baby.gender.rawValue,
            birthWeightG: baby.birthWeightG,
            birthHeightCm: baby.birthHeightCm,
            birthHeadCircumferenceCm: baby.birthHeadCircumferenceCm,
            birthChestCircumferenceCm: baby.birthChestCircumferenceCm,
            bloodType: baby.bloodType?.rawValue,
            rhFactor: baby.rhFactor?.rawValue,
            photoUrl: baby.photoUrl
        )
    }
}
