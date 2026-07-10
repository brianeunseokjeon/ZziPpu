// Data/Network/APIClient.swift
// 공용 HTTP 클라이언트 — Bearer 주입·snake_case·401 세션 무효화·쓰기 재시도

import Foundation

final class APIClient {

    // MARK: - Configuration

    private let baseURL: URL
    private let tokenProvider: () -> String?
    private let onUnauthorized: () -> Void
    private let session: URLSession

    private let decoder = JSONDecoder.apiDecoder()
    private let encoder = JSONEncoder.apiEncoder()

    /// 쓰기(POST/PATCH/PUT/DELETE) 재시도 딜레이 (초)
    private let retryDelays: [Double] = [0.5, 1.0, 2.0]

    // MARK: - Init

    init(
        baseURL: URL = AuthConfig.baseURL,
        tokenProvider: @escaping () -> String?,
        onUnauthorized: @escaping () -> Void,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.onUnauthorized = onUnauthorized
        self.session = session
    }

    // MARK: - Public API

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        let req = try buildRequest(method: "GET", path: path, query: query, body: nil as EmptyBody?)
        return try await performRead(req)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let req = try buildRequest(method: "POST", path: path, query: [:], body: body)
        return try await performWrite(req)
    }

    func postNoContent<B: Encodable>(_ path: String, body: B) async throws {
        let req = try buildRequest(method: "POST", path: path, query: [:], body: body)
        try await performWriteNoContent(req)
    }

    func patch<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let req = try buildRequest(method: "PATCH", path: path, query: [:], body: body)
        return try await performWrite(req)
    }

    func put<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let req = try buildRequest(method: "PUT", path: path, query: [:], body: body)
        return try await performWrite(req)
    }

    func delete(_ path: String) async throws {
        let req = try buildRequest(method: "DELETE", path: path, query: [:], body: nil as EmptyBody?)
        try await performWriteNoContent(req)
    }

    // MARK: - Request Builder

    private func buildRequest<B: Encodable>(
        method: String,
        path: String,
        query: [String: String],
        body: B?
    ) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    // MARK: - Read (단순 수행, 실패 시 에러 노출)

    private func performRead<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if let err = http.asAPIError(data: data) {
            if case .unauthorized = err { onUnauthorized() }
            throw err
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    // MARK: - Write (재시도 + 에러 처리)

    private func performWrite<T: Decodable>(_ request: URLRequest) async throws -> T {
        return try await withRetry {
            let (data, response) = try await self.session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            if let err = http.asAPIError(data: data) {
                if case .unauthorized = err { self.onUnauthorized() }
                throw err
            }
            do {
                return try self.decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        }
    }

    private func performWriteNoContent(_ request: URLRequest) async throws {
        try await withRetryNoContent {
            let (data, response) = try await self.session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            if let err = http.asAPIError(data: data) {
                if case .unauthorized = err { self.onUnauthorized() }
                throw err
            }
        }
    }

    // MARK: - Retry Logic (지수 백오프)

    private func withRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        for (index, delay) in ([0.0] + retryDelays).enumerated() {
            if index > 0 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            do {
                return try await operation()
            } catch let error as APIError {
                // 4xx(클라이언트 오류)는 재시도 불필요
                switch error {
                case .unauthorized, .notFound, .clientError, .decodingFailed:
                    throw error
                case .serverError, .invalidResponse:
                    lastError = error
                }
            } catch {
                lastError = error
            }
        }
        throw lastError ?? APIError.invalidResponse
    }

    private func withRetryNoContent(_ operation: @escaping () async throws -> Void) async throws {
        var lastError: Error?
        for (index, delay) in ([0.0] + retryDelays).enumerated() {
            if index > 0 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            do {
                try await operation()
                return
            } catch let error as APIError {
                switch error {
                case .unauthorized, .notFound, .clientError, .decodingFailed:
                    throw error
                case .serverError, .invalidResponse:
                    lastError = error
                }
            } catch {
                lastError = error
            }
        }
        throw lastError ?? APIError.invalidResponse
    }
}

// MARK: - Helpers

/// 바디 없는 요청 placeholder (nil-able 제네릭용)
private struct EmptyBody: Encodable {}
