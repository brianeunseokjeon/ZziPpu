// Feature/Dashboard/GrowthViewModel.swift
// 성장곡선 상세 ViewModel — GrowthRepository 로드 + 입력 시트.

import Foundation
import Observation

// MARK: - GrowthMetric

enum GrowthMetric: String, CaseIterable, Identifiable {
    case weight = "체중"
    case height = "키"
    case head   = "머리둘레"

    var id: String { rawValue }
    var unit: String {
        switch self {
        case .weight: return "kg"
        case .height: return "cm"
        case .head:   return "cm"
        }
    }
}

// MARK: - WHO 밴드 (차트 오버레이용)

/// WHO 백분위 밴드 스펙 — 아기 나이(개월)에서 보간한 값. y는 지표 단위(kg/cm).
struct WHOBandSpec: Equatable {
    let p3: Double
    let p15: Double
    let p50: Double
    let p85: Double
    let p97: Double
}

// MARK: - GrowthViewModel

@Observable
final class GrowthViewModel {

    // MARK: - State

    var series: [GrowthRecord] = []
    var selectedMetric: GrowthMetric = .weight
    var isLoading: Bool = false
    var errorMessage: String?

    // 성장 입력 시트
    var showInputSheet: Bool = false

    // 활성 아기(성별·나이 → WHO 밴드 선택)
    var activeBaby: Baby?

    // MARK: - Dependencies

    private let growthRepository:    GrowthRepository
    private let babyRepository:      BabyRepository?
    private let guidelineRepository: GuidelineRepository?
    private let babyId: UUID

    // MARK: - Init

    init(
        growthRepository: GrowthRepository,
        babyId: UUID,
        babyRepository: BabyRepository? = nil,
        guidelineRepository: GuidelineRepository? = nil
    ) {
        self.growthRepository    = growthRepository
        self.babyId              = babyId
        self.babyRepository      = babyRepository
        self.guidelineRepository = guidelineRepository
    }

    // MARK: - Actions

    func loadSeries() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                series = try await growthRepository.series(babyId: babyId)
                if let baby = try await babyRepository?.fetch(id: babyId) {
                    activeBaby = baby
                }
            } catch {
                errorMessage = "성장 기록 로드 실패: \(error.localizedDescription)"
            }
        }
    }

    func saveRecord(_ record: GrowthRecord) async {
        do {
            let confirmed = try await growthRepository.create(record)
            await MainActor.run {
                series.append(confirmed)
                series.sort { $0.recordedAt < $1.recordedAt }
            }
        } catch {
            await MainActor.run {
                errorMessage = "성장 기록 저장 실패: \(error.localizedDescription)"
            }
        }
    }

    func deleteRecord(_ record: GrowthRecord) {
        series.removeAll { $0.id == record.id }
        Task { @MainActor in
            do {
                try await growthRepository.delete(id: record.id, babyId: record.babyId)
            } catch {
                series.append(record)
                series.sort { $0.recordedAt < $1.recordedAt }
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Computed: 선택 지표 차트 포인트

    var chartPoints: [MetricPoint] {
        series.compactMap { record -> MetricPoint? in
            let value: Double
            switch selectedMetric {
            case .weight:
                guard let w = record.weightG else { return nil }
                value = Double(w) / 1000.0
            case .height:
                guard let h = record.heightCm else { return nil }
                value = h
            case .head:
                guard let hc = record.headCircumferenceCm else { return nil }
                value = hc
            }
            return MetricPoint(date: record.recordedAt, value: value)
        }
    }

    // MARK: - WHO 백분위 밴드 (선택 지표 + 성별 + 나이 기반)

    /// 현재 선택 지표·아기 성별·나이에서 보간한 WHO 백분위 밴드.
    /// - WHO 데이터는 현재 **체중 남/여만** 존재 → 키·머리둘레는 nil(밴드 생략, 크래시 금지).
    /// - 로드/디코드 실패 시에도 throw를 삼켜 nil 반환.
    var whoBand: WHOBandSpec? {
        guard let repo = guidelineRepository else { return nil }
        guard let metric = whoMetric else { return nil }        // 미지원 지표 가드
        guard let sex = whoSex else { return nil }               // 성별 미상 가드
        let months = ageMonths
        do {
            let table = try repo.whoGrowthTable(metric: metric, sex: sex)
            return interpolate(table: table, months: months)
        } catch {
            return nil   // WHO 미제공/디코드 실패 → 밴드 생략(앱 유지)
        }
    }

    /// 선택 지표 → WHO 파일 metric. WHO 미제공 지표는 nil.
    private var whoMetric: WHOGrowthMetric? {
        switch selectedMetric {
        case .weight: return .weight
        case .height: return nil   // WHO 데이터 미번들 → 생략
        case .head:   return nil   // WHO 데이터 미번들 → 생략
        }
    }

    private var whoSex: WHOGrowthSex? {
        switch activeBaby?.gender {
        case .male:   return .boy
        case .female: return .girl
        default:      return nil   // 미선택 → 밴드 생략
        }
    }

    /// 출생일 → 오늘 개월수(0 이상).
    private var ageMonths: Int {
        guard let birth = activeBaby?.birthDate else { return 0 }
        let comps = Calendar.current.dateComponents([.month], from: birth, to: .now)
        return max(0, comps.month ?? 0)
    }

    /// 월령 사이 선형보간. 범위를 벗어나면 양끝값으로 클램프.
    private func interpolate(table: WHOGrowthTable, months: Int) -> WHOBandSpec? {
        let rows = table.rows.sorted { $0.m < $1.m }
        guard let first = rows.first, let last = rows.last else { return nil }
        if months <= first.m { return spec(first) }
        if months >= last.m  { return spec(last) }

        // months를 감싸는 두 행 찾기.
        var lower = first, upper = last
        for i in 0..<(rows.count - 1) where rows[i].m <= months && months <= rows[i + 1].m {
            lower = rows[i]; upper = rows[i + 1]; break
        }
        let span = Double(upper.m - lower.m)
        let t = span > 0 ? Double(months - lower.m) / span : 0
        func lerp(_ a: Double, _ b: Double) -> Double { a + (b - a) * t }
        return WHOBandSpec(
            p3:  lerp(lower.p3,  upper.p3),
            p15: lerp(lower.p15, upper.p15),
            p50: lerp(lower.p50, upper.p50),
            p85: lerp(lower.p85, upper.p85),
            p97: lerp(lower.p97, upper.p97)
        )
    }

    private func spec(_ r: WHOGrowthRow) -> WHOBandSpec {
        WHOBandSpec(p3: r.p3, p15: r.p15, p50: r.p50, p85: r.p85, p97: r.p97)
    }

    /// 실측 최신값이 대략 몇 백분위 근처인지 완곡 코멘트(정밀 진단 아님).
    var whoPercentileComment: String? {
        guard let band = whoBand, let latest = chartPoints.last?.value else { return nil }
        let label: String
        switch latest {
        case ..<band.p3:            label = "3백분위보다 낮은 편"
        case band.p3..<band.p15:    label = "약 3~15백분위"
        case band.p15..<band.p50:   label = "약 15~50백분위"
        case band.p50..<band.p85:   label = "약 50~85백분위 (또래 평균 수준)"
        case band.p85..<band.p97:   label = "약 85~97백분위"
        default:                    label = "97백분위보다 높은 편"
        }
        return "\(label)예요. 개인차는 정상이며 정밀 진단은 아니에요."
    }

    var latestValueText: String {
        guard let last = series.last else { return "—" }
        switch selectedMetric {
        case .weight:
            guard let w = last.weightG else { return "—" }
            return String(format: "%.2fkg", Double(w) / 1000.0)
        case .height:
            guard let h = last.heightCm else { return "—" }
            return String(format: "%.1fcm", h)
        case .head:
            guard let hc = last.headCircumferenceCm else { return "—" }
            return String(format: "%.1fcm", hc)
        }
    }
}
