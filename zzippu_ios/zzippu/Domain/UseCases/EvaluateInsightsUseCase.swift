// Domain/UseCases/EvaluateInsightsUseCase.swift
// 비교·코멘트 엔진 — 아기 나이/체중 + 집계값 → 지표별 DomainInsight.
// 순수(Foundation only). GuidelineRepository 프로토콜에만 의존 → 테스트 가능.
//
// 규칙 요지(INSIGHTS_PLAN §B):
//  - 수유: recMin=kg×150(cap960), recMax=kg×180(cap960). ±20% 완충. 체중없음/모유수유→noData.
//  - 수면: <minH low, >maxH high(info톤). 상한 초과는 경보 아님.
//  - 소변: <peeMin low(주의). 상한 없음.
//  - 대변: poopMin~poopMax 밖 → info(참고). danger 절대 금지.
//  - 터미타임: ≥minMin ok, else low(완곡).
//  - validDays<3 → 전 지표 noData.
// 톤: 단정·경보 금지, 완곡·권유형, 이모지 1개 이하.

import Foundation

struct EvaluateInsightsUseCase {

    private let repository: GuidelineRepository

    init(repository: GuidelineRepository) {
        self.repository = repository
    }

    /// 지표별 인사이트 목록. 순서: 수유·수면·소변·대변·터미타임.
    func evaluate(_ input: InsightInput) throws -> [DomainInsight] {
        let g = try repository.pediatricGuideline()
        return [
            feedingInsight(input, g),
            sleepInsight(input, g),
            peeInsight(input, g),
            poopInsight(input, g),
            tummyTimeInsight(input, g)
        ]
    }

    /// 전 지표 롤업 한 줄 요약(카드 상단용).
    func rollupHeadline(_ insights: [DomainInsight]) -> String {
        let evaluated = insights.filter { $0.status != .noData }
        guard !evaluated.isEmpty else {
            return "기록이 더 쌓이면 분석해 드릴게요 📊"
        }
        let allOk = evaluated.allSatisfy { $0.status == .ok }
        if allOk { return "잘 먹고·잘 자고 있어요 👍" }
        let lows = evaluated.filter { $0.status == .low }
        if !lows.isEmpty {
            return "대체로 좋아요. \(lows.first!.title)을(를) 조금 더 살펴볼까요?"
        }
        return "대체로 권장 범위 안이에요 😊"
    }

    // MARK: - Feeding

    private func feedingInsight(_ input: InsightInput, _ g: PediatricGuideline) -> DomainInsight {
        let src = g.feeding.source
        func make(_ status: InsightStatus, _ comment: String, range: ClosedRange<Double>? = nil) -> DomainInsight {
            DomainInsight(kind: .feeding, status: status, title: "수유",
                          comment: comment, recommendedRange: range,
                          actual: input.feedingMlPerDay, source: src)
        }

        if input.validDays < 3 {
            return make(.noData, "기록이 더 쌓이면 수유 추세를 분석해 드릴게요 📊")
        }
        if input.isBreastfeeding {
            return make(.noData, "모유수유는 양 측정이 어려워 비교는 생략해요. 체중 변화로 확인해 보세요 🤱")
        }
        guard let kg = input.weightKg, kg > 0 else {
            return make(.noData, "체중을 등록하면 AAP 권장과 비교해 드려요")
        }
        guard let actual = input.feedingMlPerDay else {
            return make(.noData, "수유 기록이 쌓이면 분석해 드릴게요 🍼")
        }

        let recMin = g.feeding.recommendedMin(weightKg: kg)
        let recMax = g.feeding.recommendedMax(weightKg: kg)
        let range = recMin...recMax
        let tol = g.feeding.tolerance
        let a = Int(actual.rounded())
        let lo = Int(recMin), hi = Int(recMax)

        if actual < recMin * (1 - tol) {
            return make(.low, "오늘 수유 \(a)ml — 권장 \(lo)~\(hi)ml보다 적어요. 체중 변화도 함께 살펴보세요", range: range)
        } else if actual > recMax * (1 + tol) {
            return make(.high, "오늘 수유 \(a)ml — 권장 \(lo)~\(hi)ml보다 많아요. 보통은 괜찮지만 이상이 있으면 소아과 상담을 권장드려요", range: range)
        } else {
            return make(.ok, "오늘 수유 \(a)ml — 권장 \(lo)~\(hi)ml 안이에요 👍", range: range)
        }
    }

    // MARK: - Sleep

    private func sleepInsight(_ input: InsightInput, _ g: PediatricGuideline) -> DomainInsight {
        let src = g.sources.sleep
        let band = g.sleep.band(forMonths: input.ageMonths)
        func make(_ status: InsightStatus, _ comment: String, range: ClosedRange<Double>? = nil) -> DomainInsight {
            DomainInsight(kind: .sleep, status: status, title: "수면",
                          comment: comment, recommendedRange: range,
                          actual: input.sleepHoursPerDay, source: src)
        }

        if input.validDays < 3 {
            return make(.noData, "기록이 더 쌓이면 수면 추세를 분석해 드릴게요 📊")
        }
        guard let band, let actual = input.sleepHoursPerDay else {
            return make(.noData, "수면 기록이 쌓이면 분석해 드릴게요 😴")
        }
        let range = band.minH...band.maxH
        let h = String(format: "%.1f", actual)
        let lo = Int(band.minH), hi = Int(band.maxH)

        if actual < band.minH {
            return make(.low, "하루 \(h)시간 — 권장(\(lo)~\(hi)시간)보다 짧아요. 조금 더 재워볼까요?", range: range)
        } else if actual > band.maxH {
            return make(.high, "하루 \(h)시간 — 권장(\(lo)~\(hi)시간)보다 길어요. 보통은 괜찮아요", range: range)
        } else {
            return make(.ok, "권장(\(lo)~\(hi)시간) 범위 내예요 😴", range: range)
        }
    }

    // MARK: - Pee (소변)

    private func peeInsight(_ input: InsightInput, _ g: PediatricGuideline) -> DomainInsight {
        let src = g.sources.diaper
        let band = g.diaper.band(forMonths: input.ageMonths)
        func make(_ status: InsightStatus, _ comment: String, range: ClosedRange<Double>? = nil) -> DomainInsight {
            DomainInsight(kind: .pee, status: status, title: "소변",
                          comment: comment, recommendedRange: range,
                          actual: input.peeCountPerDay, source: src)
        }

        if input.validDays < 3 {
            return make(.noData, "기록이 더 쌓이면 배변 추세를 분석해 드릴게요 📊")
        }
        guard let band, let actual = input.peeCountPerDay else {
            return make(.noData, "소변 기록이 쌓이면 분석해 드릴게요")
        }
        let c = Int(actual.rounded())
        if actual < Double(band.peeMin) {
            return make(.low, "하루 \(c)회 — 보통 \(band.peeMin)회 이상이에요. 수분 섭취를 살펴보고 이상이 있으면 소아과 상담을 권장드려요")
        } else {
            return make(.ok, "하루 \(c)회 — 충분히 잘 보고 있어요 👍")
        }
    }

    // MARK: - Poop (대변) — 참고톤만, danger 금지

    private func poopInsight(_ input: InsightInput, _ g: PediatricGuideline) -> DomainInsight {
        let src = g.sources.diaper
        let band = g.diaper.band(forMonths: input.ageMonths)
        func make(_ status: InsightStatus, _ comment: String) -> DomainInsight {
            // 대변은 항상 ok(적정) 또는 info(참고) — low/high(경보성) 미사용.
            DomainInsight(kind: .poop, status: status, title: "대변",
                          comment: comment, recommendedRange: nil,
                          actual: input.poopCountPerDay, source: src)
        }

        if input.validDays < 3 {
            return make(.noData, "기록이 더 쌓이면 배변 추세를 분석해 드릴게요 📊")
        }
        guard let band, let actual = input.poopCountPerDay else {
            return make(.noData, "대변 기록이 쌓이면 분석해 드릴게요")
        }
        let c = Int(actual.rounded())
        if actual < Double(band.poopMin) || actual > Double(band.poopMax) {
            // 공식 상한 없음 → 정보(참고) 톤.
            return make(.noData, "하루 \(c)회 — 참고 범위(\(band.poopMin)~\(band.poopMax)회)와 조금 달라요. 개인차는 정상이며, 갑작스러운 변화만 살펴보세요")
        } else {
            return make(.ok, "하루 \(c)회 — 참고 범위(\(band.poopMin)~\(band.poopMax)회) 안이에요 👍")
        }
    }

    // MARK: - Tummy time (터미타임)

    private func tummyTimeInsight(_ input: InsightInput, _ g: PediatricGuideline) -> DomainInsight {
        let src = g.feeding.source // 대체 출처 없음: AAP Tummy to Play (feeding과 동일 AAP 계열)
        let band = g.tummyTime.band(forMonths: input.ageMonths)
        func make(_ status: InsightStatus, _ comment: String, range: ClosedRange<Double>? = nil) -> DomainInsight {
            DomainInsight(kind: .tummyTime, status: status, title: "터미타임",
                          comment: comment, recommendedRange: range,
                          actual: input.tummyTimeMinPerDay, source: "AAP — Tummy to Play")
        }

        if input.validDays < 3 {
            return make(.noData, "기록이 더 쌓이면 터미타임을 분석해 드릴게요 📊")
        }
        guard let band else {
            return make(.noData, "이 연령대는 터미타임 권장이 따로 없어요")
        }
        let range = Double(band.minMin)...Double(band.targetMin)
        let actual = input.tummyTimeMinPerDay ?? 0
        let m = Int(actual.rounded())

        if actual >= Double(band.minMin) {
            return make(.ok, "하루 \(m)분 — 목표(\(band.targetMin)분)에 잘 맞춰가고 있어요 💪", range: range)
        } else {
            return make(.low, "하루 \(m)분 — 권장은 \(band.targetMin)분이에요. 조금씩 늘려볼까요?", range: range)
        }
    }
}
