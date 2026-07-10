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

    // MARK: - Dependencies

    private let growthRepository: GrowthRepository
    private let babyId: UUID

    // MARK: - Init

    init(growthRepository: GrowthRepository, babyId: UUID) {
        self.growthRepository = growthRepository
        self.babyId           = babyId
    }

    // MARK: - Actions

    func loadSeries() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                series = try await growthRepository.series(babyId: babyId)
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
