// Domain/UseCases/SaveFeedingUseCase.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

final class SaveFeedingUseCase {
    private let repository: FeedingRepository

    init(repository: FeedingRepository) {
        self.repository = repository
    }

    /// 새 수유 기록 저장
    func execute(_ feeding: Feeding) throws {
        // 도메인 규칙 검증
        if feeding.type == .formula, let ml = feeding.amountMl, ml <= 0 {
            throw DomainError.invalidInput("분유량은 0ml 이상이어야 합니다.")
        }
        try repository.create(feeding)
    }
}
