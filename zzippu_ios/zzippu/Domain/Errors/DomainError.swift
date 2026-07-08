// Domain/Errors/DomainError.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum DomainError: Error, LocalizedError {
    case notFound(id: UUID)
    case invalidInput(String)
    case persistenceFailed(underlying: Error)
    case unauthorized   // 토큰 없이 인증 필요 API 호출

    var errorDescription: String? {
        switch self {
        case .notFound(let id):          return "항목을 찾을 수 없습니다: \(id)"
        case .invalidInput(let msg):     return "잘못된 입력: \(msg)"
        case .persistenceFailed(let e):  return "저장 실패: \(e.localizedDescription)"
        case .unauthorized:              return "로그인이 필요합니다."
        }
    }
}
