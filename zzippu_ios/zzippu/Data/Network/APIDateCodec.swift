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

    /// 서버 datetime → Date. 다양한 포맷을 견고하게 처리한다.
    /// 서버(Python/FastAPI + UTCDateTime)는 `2026-06-05T12:34:56.789123+00:00`
    /// 처럼 **타임존 있는 6자리 마이크로초**를 보낸다. ISO8601DateFormatter 는
    /// 밀리초(3자리)까지만 지원하므로 마이크로초에서 실패 → 아래 폴백들이 필요.
    static func parseDateTime(_ string: String) -> Date? {
        // 1) ISO8601 (3자리 ms + 타임존)
        let isoMs = ISO8601DateFormatter()
        isoMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoMs.date(from: string) { return d }

        // 2) ISO8601 (소수 없음 + 타임존: Z 또는 +00:00)
        let isoPlain = ISO8601DateFormatter()
        isoPlain.formatOptions = [.withInternetDateTime]
        if let d = isoPlain.date(from: string) { return d }

        // 3) 소수(마이크로초 등)를 제거하고 재시도 → 6자리 마이크로초 케이스 해결.
        //    (초 미만 정밀도는 이 앱에 무의미하므로 잘라도 안전.)
        if let range = string.range(of: #"\.\d+"#, options: .regularExpression) {
            let stripped = string.replacingCharacters(in: range, with: "")
            if let d = isoPlain.date(from: stripped) { return d }              // 타임존 있는 경우
            if let d = naiveFormatter.date(from: stripped) { return d }        // naive(타임존 없는 경우)
        }

        // 4) naive datetime (타임존 표기 자체가 없는 경우 — UTC 로 간주)
        if let d = naiveFormatter.date(from: string) { return d }

        return nil
    }

    /// 타임존 표기 없는 `yyyy-MM-dd'T'HH:mm:ss` (UTC 간주)
    private static let naiveFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // MARK: - date (YYYY-MM-DD, 서버 birth_date, growth recorded_at 등)

    // 날짜 전용 필드/조회는 **KST(Asia/Seoul) 기준**이어야 한다.
    // 서버가 date 조회를 kst_date_eq(KST 날짜)로 필터하고, 홈도 KST로 날짜를 계산하므로
    // UTC로 포맷하면 KST 자정(=UTC 전날 15시)이 하루 밀려 "기록 없음"으로 어긋난다(웹은 KST 전송).
    static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .kst
        return f
    }()

    /// YYYY-MM-DD String → Date (KST 자정 기준)
    static func parseDate(_ string: String) -> Date? {
        dateOnlyFormatter.date(from: string)
    }

    /// Date → YYYY-MM-DD String (KST 기준 — 서버 date 조회/저장과 정합)
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
