// Domain/Repositories/BabyRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol BabyRepository {
    func create(_ baby: Baby) async throws -> Baby
    func update(_ baby: Baby) async throws -> Baby
    func fetch(id: UUID) async throws -> Baby?
    func fetchAll() async throws -> [Baby]
    func activeBaby() async throws -> Baby?       // fetchAll().first (MVP)
    func joinByCode(_ code: String) async throws -> Baby   // 공유 합류(caregiver)
}
