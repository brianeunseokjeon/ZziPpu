// Domain/Entities/DomainInsight.swift
// 비교·코멘트 엔진(EvaluateInsightsUseCase) 출력 모델 — 순수.
// Foundation only. StatusTone(디자인시스템)만 참조 — DS 값 타입이라 Domain에서 사용 허용.

import Foundation

// MARK: - InsightKind (지표)

enum InsightKind: String, Sendable, CaseIterable {
    case feeding    // 수유(ml/일)
    case sleep      // 총 수면(h/일)
    case pee        // 소변 횟수/일
    case poop       // 대변 횟수/일 (참고톤)
    case tummyTime  // 터미타임(분/일)
}

// MARK: - InsightStatus (판정)

/// 판정 상태. `tone`으로 StatusTone에 매핑(ok→success, low→warning, high→info, noData→info).
enum InsightStatus: String, Sendable {
    case ok       // 적정
    case low      // 부족
    case high     // 과다(경보 아님 — info 톤)
    case noData   // 데이터 부족/전제 미충족

    var tone: StatusTone {
        switch self {
        case .ok:     return .success
        case .low:    return .warning
        case .high:   return .info      // 상한 초과는 danger 아닌 info(완곡)
        case .noData: return .info      // 회색톤 정보
        }
    }

    /// 상태 pill 라벨.
    var pillLabel: String {
        switch self {
        case .ok:     return "적정"
        case .low:    return "권장보다 적음"
        case .high:   return "권장보다 많음"
        case .noData: return "정보 없음"
        }
    }
}

// MARK: - DomainInsight

/// 지표별 인사이트 결과. UI는 이걸 InsightRow에 바인딩.
struct DomainInsight: Identifiable, Equatable, Sendable {
    var id: InsightKind { kind }

    let kind: InsightKind
    let status: InsightStatus
    let title: String                          // 지표 라벨 (예: "수유")
    let comment: String                        // 부드러운 코멘트 문구
    let recommendedRange: ClosedRange<Double>? // 권장 범위(있을 때)
    let actual: Double?                         // 실측 집계값
    let source: String                         // 출처 문구

    var tone: StatusTone { status.tone }
}

// MARK: - InsightInput (엔진 입력)

/// EvaluateInsightsUseCase 입력. 집계는 상위(ViewModel)가 계산해 전달.
struct InsightInput: Equatable, Sendable {
    let ageMonths: Int
    let weightKg: Double?          // 없으면 수유 비교 noData
    let isBreastfeeding: Bool      // true면 수유 ml 비교 제외
    let validDays: Int             // 유효 기록 일수 (<3이면 noData)

    let feedingMlPerDay: Double?
    let sleepHoursPerDay: Double?
    let peeCountPerDay: Double?
    let poopCountPerDay: Double?
    let tummyTimeMinPerDay: Double?

    init(
        ageMonths: Int,
        weightKg: Double? = nil,
        isBreastfeeding: Bool = false,
        validDays: Int,
        feedingMlPerDay: Double? = nil,
        sleepHoursPerDay: Double? = nil,
        peeCountPerDay: Double? = nil,
        poopCountPerDay: Double? = nil,
        tummyTimeMinPerDay: Double? = nil
    ) {
        self.ageMonths = ageMonths
        self.weightKg = weightKg
        self.isBreastfeeding = isBreastfeeding
        self.validDays = validDays
        self.feedingMlPerDay = feedingMlPerDay
        self.sleepHoursPerDay = sleepHoursPerDay
        self.peeCountPerDay = peeCountPerDay
        self.poopCountPerDay = poopCountPerDay
        self.tummyTimeMinPerDay = tummyTimeMinPerDay
    }
}
