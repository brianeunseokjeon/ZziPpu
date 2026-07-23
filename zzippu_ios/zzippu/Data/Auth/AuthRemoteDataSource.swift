// Data/Auth/AuthRemoteDataSource.swift
// PRODUCT_SPEC §1.1 API 구현 — 서버를 아는 유일한 코드

import Foundation

final class AuthRemoteDataSource {

    // MARK: - Request OTP (POST /api/v1/auth/email/request)

    func requestEmailOtp(email: String) async throws {
        let url = AuthConfig.baseURL.appendingPathComponent("/api/v1/auth/email/request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try AuthConfig.encoder.encode(["email": email])

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateStatus(response, expected: 204)
    }

    // MARK: - Verify OTP (POST /api/v1/auth/email/verify)

    func verifyEmailOtp(email: String, code: String) async throws -> AuthSessionDTO {
        let url = AuthConfig.baseURL.appendingPathComponent("/api/v1/auth/email/verify")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Body: Encodable { let email: String; let code: String }
        request.httpBody = try AuthConfig.encoder.encode(Body(email: email, code: code))

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateStatus(response, expected: 200)
        return try AuthConfig.decoder.decode(AuthSessionDTO.self, from: data)
    }

    // MARK: - Fetch Terms (GET /api/v1/auth/terms)

    func fetchTerms() async throws -> [TermDocDTO] {
        let url = AuthConfig.baseURL.appendingPathComponent("/api/v1/auth/terms")
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateStatus(response, expected: 200)
        return try AuthConfig.decoder.decode([TermDocDTO].self, from: data)
    }

    // MARK: - Agree Terms (POST /api/v1/auth/terms/agree, Bearer required)

    func agreeTerms(agreements: [AgreementDTO], token: String) async throws {
        let url = AuthConfig.baseURL.appendingPathComponent("/api/v1/auth/terms/agree")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        struct Body: Encodable { let agreements: [AgreementDTO] }
        request.httpBody = try AuthConfig.encoder.encode(Body(agreements: agreements))

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateStatus(response, expected: 204)
    }

    // MARK: - Withdraw Account (DELETE /api/v1/auth/account, Bearer required)

    func withdraw(token: String) async throws {
        let url = AuthConfig.baseURL.appendingPathComponent("/api/v1/auth/account")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateStatus(response, expected: 204)
    }

    // MARK: - Redeem Code (POST /api/v1/auth/code/redeem) — stub

    func redeemCode(_ code: String) async throws -> AuthSessionDTO {
        let url = AuthConfig.baseURL.appendingPathComponent("/api/v1/auth/code/redeem")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try AuthConfig.encoder.encode(["code": code])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateStatus(response, expected: 200)
        return try AuthConfig.decoder.decode(AuthSessionDTO.self, from: data)
    }

    // MARK: - Private

    private func validateStatus(_ response: URLResponse, expected: Int) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AuthNetworkError.invalidResponse
        }
        guard http.statusCode == expected else {
            throw AuthNetworkError.httpError(http.statusCode)
        }
    }
}

// MARK: - DTOs (서버 JSON 대응 — snake_case 자동 변환)

struct AuthSessionDTO: Decodable {
    let accessToken: String
    let tokenType: String?
    let userId: UUID
    let isNewUser: Bool
    let termsRequired: Bool
}

struct TermDocDTO: Decodable {
    let type: String        // "service" | "privacy"
    let version: String
    let title: String
    let content: String
    let required: Bool
}

struct AgreementDTO: Encodable {
    let type: String
    let version: String
}

// MARK: - Network Error

enum AuthNetworkError: LocalizedError {
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:      return "서버 응답이 올바르지 않습니다."
        case .httpError(let code):  return "서버 오류 (\(code))"
        }
    }
}
