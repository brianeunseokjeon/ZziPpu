// Domain/Repositories/VaccinationRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지.

import Foundation

protocol VaccinationRepository {
    func list(babyId: UUID) async throws -> [Vaccination]
    func markAdministered(
        babyId: UUID,
        id: UUID,
        administeredDate: Date,
        hospitalName: String?
    ) async throws -> Vaccination
}
