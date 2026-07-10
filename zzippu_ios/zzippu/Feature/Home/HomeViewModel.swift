// Feature/Home/HomeViewModel.swift
// 홈 기록허브 ViewModel — activeBaby 로드, 선택날짜 수유목록 로드/갱신.
// Domain 프로토콜(FeedingRepository, BabyRepository)만 의존(클린아키텍처).

import Foundation
import Observation

@Observable
final class HomeViewModel {

    // MARK: - State

    var activeBaby: Baby?
    var feedings: [Feeding] = []
    var selectedDate: Date = .now
    var isLoadingBaby: Bool = false
    var isLoadingFeedings: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies (Domain 프로토콜만)

    private let feedingRepository: FeedingRepository
    private let babyRepository: BabyRepository
    private let babyId: UUID

    // MARK: - Init

    init(feedingRepository: FeedingRepository, babyRepository: BabyRepository, babyId: UUID) {
        self.feedingRepository = feedingRepository
        self.babyRepository    = babyRepository
        self.babyId            = babyId
    }

    // MARK: - Actions

    /// activeBaby 로드 (이름·나이·성별을 헤더에 표시)
    func loadActiveBaby() {
        isLoadingBaby = true
        Task { @MainActor in
            defer { isLoadingBaby = false }
            do {
                activeBaby = try await babyRepository.fetch(id: babyId)
            } catch {
                errorMessage = "아기 정보 로드 실패: \(error.localizedDescription)"
            }
        }
    }

    /// 선택 날짜 수유 목록 로드
    func loadFeedings(for date: Date? = nil) {
        let target = date ?? selectedDate
        isLoadingFeedings = true
        Task { @MainActor in
            defer { isLoadingFeedings = false }
            do {
                feedings = try await feedingRepository.list(babyId: babyId, on: target)
            } catch {
                errorMessage = "수유 기록 로드 실패: \(error.localizedDescription)"
            }
        }
    }

    /// 날짜 변경 → 목록 재조회
    func changeDate(_ date: Date) {
        selectedDate = date
        loadFeedings(for: date)
    }

    /// 낙관적 삽입 후 서버 저장 → 타임라인 갱신
    func saveFeeding(_ feeding: Feeding) async {
        // (1) 낙관적 삽입
        feedings.insert(feeding, at: 0)

        do {
            // (2) 서버 POST
            let confirmed = try await feedingRepository.create(feeding)
            // (3) 낙관적 항목 → 서버 확정 항목으로 교체
            await MainActor.run {
                if let idx = feedings.firstIndex(where: { $0.id == feeding.id }) {
                    feedings[idx] = confirmed
                }
            }
        } catch {
            // (4) 실패 → 롤백
            await MainActor.run {
                feedings.removeAll { $0.id == feeding.id }
                errorMessage = "저장 실패: \(error.localizedDescription)"
            }
        }
    }

    /// 삭제 (낙관적)
    func deleteFeeding(_ feeding: Feeding) {
        feedings.removeAll { $0.id == feeding.id }
        Task { @MainActor in
            do {
                try await feedingRepository.delete(id: feeding.id, babyId: feeding.babyId)
            } catch {
                feedings.insert(feeding, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Computed

    /// 수유 기록 → 타임라인 그룹(분 단위)
    var feedingGroups: [FeedingTimelineGroup] {
        FeedingTimelineGroup.grouped(from: feedings)
    }
}

// MARK: - FeedingTimelineGroup

/// 수유 기록을 같은 분(minute) 기준으로 묶은 타임라인 그룹.
/// Feature 레이어 헬퍼 — Domain 엔티티에 의존하되 UI에는 비의존.
struct FeedingTimelineGroup: Identifiable {
    let id: UUID = UUID()
    let minuteKey: Date        // 분 단위 기준 시각
    let items: [Feeding]
    var isLatest: Bool = false

    static func grouped(from feedings: [Feeding]) -> [FeedingTimelineGroup] {
        guard !feedings.isEmpty else { return [] }

        let cal = Calendar.current
        // startedAt 내림차순 정렬 (최신 먼저)
        let sorted = feedings.sorted { $0.startedAt > $1.startedAt }

        // 분 단위 버킷 생성
        var buckets: [Date: [Feeding]] = [:]
        for f in sorted {
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: f.startedAt)
            let key = cal.date(from: comps) ?? f.startedAt
            buckets[key, default: []].append(f)
        }

        // 정렬 (최신 그룹 먼저)
        var groups = buckets.map { FeedingTimelineGroup(minuteKey: $0.key, items: $0.value) }
            .sorted { $0.minuteKey > $1.minuteKey }

        // 첫 그룹(최신)에 highlighted 마킹
        if !groups.isEmpty {
            groups[0].isLatest = true
        }

        return groups
    }
}

// MARK: - Feeding Label Helper (Feature 레이어)

extension Feeding {
    /// 타임라인 표시용 라벨 (예: "분유 120ml", "모유(좌) 15분")
    var timelineLabel: String {
        switch type {
        case .formula:
            if let ml = amountMl {
                return "분유 \(ml)ml"
            }
            return "분유"
        case .breastLeft:
            if let min = durationMinutes {
                return "모유(좌) \(min)분"
            }
            return "모유(좌)"
        case .breastRight:
            if let min = durationMinutes {
                return "모유(우) \(min)분"
            }
            return "모유(우)"
        case .breastBoth:
            if let min = durationMinutes {
                return "모유(양쪽) \(min)분"
            }
            return "모유(양쪽)"
        }
    }

    /// 수유 타입 → DomainKind 변환 (DS 컴포넌트용)
    var domainKind: DomainKind {
        switch type {
        case .formula:     return .feedingFormula
        case .breastLeft:  return .feedingBreastLeft
        case .breastRight: return .feedingBreastRight
        case .breastBoth:  return .feedingBreastBoth
        }
    }
}

// MARK: - Baby → AppHeaderBaby 변환 (Feature 레이어 헬퍼)

extension Baby {
    func toHeaderBaby() -> AppHeaderBaby {
        let gender: BabyGender
        switch self.gender {
        case .male:    gender = .male
        case .female:  gender = .female
        case .unknown: gender = .unknown
        }

        let photoURL: URL?
        if let str = photoUrl {
            photoURL = URL(string: str)
        } else {
            photoURL = nil
        }

        return AppHeaderBaby(
            name:      name,
            birthDate: birthDate,
            gender:    gender,
            photoURL:  photoURL
        )
    }
}
