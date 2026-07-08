// Data/Auth/AuthConfig.swift
// 인증 서버 설정 — 서버를 아는 유일한 레이어(Data/Auth)

import Foundation

enum AuthConfig {
    /// 로컬 통합 서버 (기본값)
    /// 프로덕션 전환 시: "https://zzippu-api.onrender.com" 으로 교체
    static let baseURL = URL(string: "http://localhost:8080")!

    /// JSON 디코더: snake_case → camelCase 자동 변환
    static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    /// JSON 인코더: camelCase → snake_case 자동 변환
    static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }
}
