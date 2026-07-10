// Data/Network/APIError.swift
// FastAPI 에러 바디 파싱 + 상태코드 매핑

import Foundation

/// 서버 응답 에러 (HTTP 상태코드 + 메시지)
enum APIError: LocalizedError {
    case unauthorized                        // 401 → 세션 무효화
    case notFound                            // 404
    case serverError(Int, String?)           // 5xx
    case clientError(Int, String?)           // 4xx (401/404 제외)
    case invalidResponse                     // HTTP 응답이 아님
    case decodingFailed(Error)               // JSON 파싱 실패

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "로그인이 만료되었습니다. 다시 로그인해 주세요."
        case .notFound:
            return "요청한 항목을 찾을 수 없습니다."
        case .serverError(let code, let msg):
            return "서버 오류 (\(code))\(msg.map { ": \($0)" } ?? "")"
        case .clientError(let code, let msg):
            return "요청 오류 (\(code))\(msg.map { ": \($0)" } ?? "")"
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .decodingFailed(let err):
            return "데이터 파싱 실패: \(err.localizedDescription)"
        }
    }
}

// MARK: - FastAPI 에러 바디

/// FastAPI `{ "detail": "..." }` 또는 `{ "detail": [{ "msg": ... }] }`
struct APIErrorBody: Decodable {
    let detail: DetailValue

    enum DetailValue: Decodable {
        case string(String)
        case validationErrors([ValidationError])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .string(str)
            } else if let errs = try? container.decode([ValidationError].self) {
                self = .validationErrors(errs)
            } else {
                self = .string("알 수 없는 오류")
            }
        }

        var message: String {
            switch self {
            case .string(let s): return s
            case .validationErrors(let errs): return errs.map { $0.msg }.joined(separator: ", ")
            }
        }
    }

    struct ValidationError: Decodable {
        let msg: String
    }
}

// MARK: - HTTP 응답 검증 헬퍼

extension HTTPURLResponse {
    /// 상태코드를 APIError로 변환. 정상 범위(200~299)면 nil 반환.
    func asAPIError(data: Data) -> APIError? {
        guard !(200..<300).contains(statusCode) else { return nil }
        let detailMsg = try? JSONDecoder().decode(APIErrorBody.self, from: data).detail.message

        switch statusCode {
        case 401: return .unauthorized
        case 404: return .notFound
        case 500...: return .serverError(statusCode, detailMsg)
        default:   return .clientError(statusCode, detailMsg)
        }
    }
}
