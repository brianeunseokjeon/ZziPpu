// Data/Auth/AuthConfig.swift
// 인증 서버 설정 — 서버를 아는 유일한 레이어(Data/Auth)

import Foundation

enum AuthConfig {
    /// 통합 서버(zzippu-api). 로컬 개발 시엔 "http://localhost:8080" 으로 교체.
    /// (localhost 는 HTTP 라 ATS 예외 필요 — 프로덕션 HTTPS 는 그대로 허용됨)
    static let baseURL = URL(string: "https://zzippu-api.onrender.com")!

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
