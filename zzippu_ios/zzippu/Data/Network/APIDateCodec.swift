// Data/Network/APIDateCodec.swift
// 서버 datetime(ISO8601)·date(YYYY-MM-DD) 혼용 처리
// DTO에서 date 계열을 String으로 받고 Mapper에서 이 헬퍼로 변환

import Foundation

enum APIDateCodec {

    // MARK: - datetime (ISO8601, 밀리초 유무 양쪽 허용)

    /// ISO8601 datetime 파싱 (서버의 started_at, ended_at, created_at 등)
    static func datetimeFormatter() -> ISO8601DateFormatter {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt
    }

    /// ISO8601 datetime → Date (밀리초 포함/미포함 양쪽 시도)
    static func parseDateTime(_ string: String) -> Date? {
        let withMs = ISO8601DateFormatter()
        withMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withMs.date(from: string) { return d }

        let withoutMs = ISO8601DateFormatter()
        withoutMs.formatOptions = [.withInternetDateTime]
        return withoutMs.date(from: string)
    }

    // MARK: - date (YYYY-MM-DD, 서버 birth_date, growth recorded_at 등)

    static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    /// YYYY-MM-DD String → Date (자정 UTC 기준)
    static func parseDate(_ string: String) -> Date? {
        dateOnlyFormatter.date(from: string)
    }

    /// Date → YYYY-MM-DD String (UTC 기준)
    static func formatDate(_ date: Date) -> String {
        dateOnlyFormatter.string(from: date)
    }

    /// Date → ISO8601 datetime String (서버 POST 요청용)
    static func formatDateTime(_ date: Date) -> String {
        datetimeFormatter().string(from: date)
    }
}

// MARK: - JSONDecoder/Encoder with datetime strategy

extension JSONDecoder {
    /// APIClient용 디코더: snake_case + ISO8601 datetime
    static func apiDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        // date 계열(birth_date 등)은 DTO에서 String으로 받으므로 전역 전략은 datetime만
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = APIDateCodec.parseDateTime(str) { return date }
            // YYYY-MM-DD fallback
            if let date = APIDateCodec.parseDate(str) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "날짜 파싱 실패: \(str)"
            )
        }
        return d
    }
}

extension JSONEncoder {
    /// APIClient용 인코더: snake_case + ISO8601 datetime
    static func apiEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(APIDateCodec.formatDateTime(date))
        }
        return e
    }
}
