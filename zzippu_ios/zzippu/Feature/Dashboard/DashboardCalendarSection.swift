// Feature/Dashboard/DashboardCalendarSection.swift
// 대시보드 달력 섹션 — MonthCalendarModel → DS 컴포넌트 배선.
// Domain 모델 → View DTO 변환(kind→색 매핑)은 이 파일에서.

import SwiftUI

struct DashboardCalendarSection: View {

    @Bindable var vm: CalendarViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        CardContainer(style: .plain) {
            VStack(alignment: .leading, spacing: theme.space.stackGapMd) {

                // 월 헤더
                MonthHeaderView(
                    month: vm.currentMonth,
                    canGoPrevious: vm.canGoPrevious,
                    canGoNext: vm.canGoNext,
                    isShowingToday: vm.isShowingToday,
                    onPrevious: { vm.goToPreviousMonth() },
                    onNext:     { vm.goToNextMonth() },
                    onToday:    { vm.goToToday() }
                )

                // 요일 헤더
                WeekdayHeaderView()

                // 그리드 (좌우 패딩 상쇄 — 셀이 카드 폭을 꽉 채움)
                calendarGrid
                    .padding(.horizontal, -theme.component.card.padding + theme.component.calendarCell.spacing)

                // 범례
                legendView

                // 검진 배너
                if vm.isLoading {
                    skeletonBanner
                } else {
                    CheckupBannerView(bannerInfo: vm.calendarModel.bannerInfo)
                }
            }
        }
        .onAppear { vm.loadBaby() }
    }

    // MARK: - Grid

    @ViewBuilder
    private var calendarGrid: some View {
        if vm.isLoading && vm.calendarModel.days.isEmpty {
            skeletonGrid
        } else {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: theme.component.calendarCell.spacing),
                    count: 7
                ),
                spacing: theme.component.calendarCell.spacing
            ) {
                ForEach(Array(vm.calendarModel.days.enumerated()), id: \.element.id) { idx, day in
                    CalendarCellView(
                        dto:          makeDTO(day: day),
                        isWeekend:    (idx % 7 == 0 || idx % 7 == 6),
                        weekdayIndex: idx % 7
                    )
                }
            }
        }
    }

    // MARK: - DTO 변환 (Domain → DS 색 없는 DTO)

    private func makeDTO(day: CalendarDay) -> CalendarCellDTO {
        let cal = Calendar.kst
        let dayNum = cal.component(.day, from: day.date)

        // eventBadge 데코 → EventBadgeDTO (colorIndex = 검진 차수)
        let badges = day.eventBadgeDecorations.map {
            EventBadgeDTO(label: $0.text ?? "", kind: $0.kind, round: $0.colorIndex ?? 1)
        }
        // underbar 데코 → UnderbarDTO (최대 2겹, 차수별 색)
        let underbars = day.underbarDecorations.map {
            UnderbarDTO(spanRole: $0.spanRole ?? .middle, kind: $0.kind, round: $0.colorIndex ?? 1)
        }

        return CalendarCellDTO(
            dateNumber:        dayNum,
            volumeText:        day.isOutsideMonth ? nil : day.volumeText,
            isToday:           day.isToday,
            isOutside:         day.isOutsideMonth,
            isFuture:          day.isFuture,
            eventBadges:       day.isOutsideMonth ? [] : badges,
            underbars:         day.isOutsideMonth ? [] : underbars,
            accessibilityLabel: day.accessibilityLabel(monthFormatter: monthFormatter)
        )
    }

    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.timeZone = .kst
        f.setLocalizedDateFormatFromTemplate("MMMM")   // 기기 언어. ko "7월" / en "July"
        return f
    }()

    // MARK: - 범례

    private var legendView: some View {
        HStack(spacing: theme.space.inlineGap) {
            Text("숫자 = 하루 총 수유량(ml)")
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textTertiary.color)

            Text("·")
                .foregroundStyle(theme.color.textTertiary.color)

            // 검진 범례 — 차수별 색(대표 3색 도트로 힌트)
            HStack(spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(1...3, id: \.self) { round in
                        Circle()
                            .fill(theme.color.checkupColor(round: round).color)
                            .frame(width: 6, height: 6)
                    }
                }
                Text("검진(차수별 색)")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textTertiary.color)
            }
        }
    }

    // MARK: - Skeleton (로딩)

    private var skeletonGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
            spacing: 4
        ) {
            ForEach(0..<42, id: \.self) { i in
                VStack(spacing: 2) {
                    // 날짜 숫자 자리 (스켈레톤)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.color.surfaceSunken.color)
                        .frame(width: 20, height: 14)
                    // 수유량 자리 shimmer
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.color.surfaceSunken.color)
                        .frame(width: 28, height: 8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: theme.component.calendarCell.minHeight)
            }
        }
    }

    private var skeletonBanner: some View {
        RoundedRectangle(cornerRadius: theme.radius.control)
            .fill(theme.color.surfaceSunken.color)
            .frame(height: 48)
    }
}

// MARK: - Preview Helpers

private struct MockFeedingRepository: FeedingRepository {
    func create(_ feeding: Feeding) async throws -> Feeding { feeding }
    func update(_ feeding: Feeding) async throws -> Feeding { feeding }
    func delete(id: UUID, babyId: UUID) async throws {}
    func fetch(id: UUID, babyId: UUID) async throws -> Feeding? { nil }
    func list(babyId: UUID, on day: Date) async throws -> [Feeding] { [] }
    func lastFeeding(babyId: UUID) async throws -> Feeding? { nil }
    func dailyTotals(babyId: UUID, from start: Date, to end: Date) async throws -> [DateVolume] {
        let cal = Calendar.kst
        // 목 데이터: 오늘 기준 임의 수유량
        var result: [DateVolume] = []
        var d = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        let today = cal.startOfDay(for: Date.now)
        while d <= e && d <= today {
            let ml = Int.random(in: 300...900)
            result.append(DateVolume(day: d, totalMl: ml))
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return result
    }
}

private struct MockBabyRepository: BabyRepository {
    let baby: Baby
    func create(_ baby: Baby) async throws -> Baby { baby }
    func update(_ baby: Baby) async throws -> Baby { baby }
    func fetch(id: UUID) async throws -> Baby? { baby }
    func fetchAll() async throws -> [Baby] { [baby] }
    func activeBaby() async throws -> Baby? { baby }
    func joinByCode(_ code: String) async throws -> Baby { baby }
}

private struct CalendarSectionPreviewContainer: View {
    @State private var vm: CalendarViewModel

    init(birthDate: Date) {
        let babyId = UUID()
        let baby = Baby(
            id: babyId, userId: nil,
            name: "테스트",
            birthDate: birthDate,
            gender: .male,
            birthWeightG: 3200,
            birthHeightCm: nil,
            birthHeadCircumferenceCm: nil,
            birthChestCircumferenceCm: nil,
            bloodType: nil,
            rhFactor: nil,
            photoUrl: nil,
            createdAt: Date.now
        )
        _vm = State(initialValue: CalendarViewModel(
            feedingRepository: MockFeedingRepository(),
            babyRepository:    MockBabyRepository(baby: baby),
            babyId:            babyId
        ))
    }

    var body: some View {
        ScrollView {
            DashboardCalendarSection(vm: vm)
                .padding(.horizontal, 16)
        }
    }
}

#Preview("DashboardCalendarSection — light") {
    // 2026-04-22 생 → 2차 검진 2026-08-22~11-21 예시
    let birthDate = Calendar.kst.date(from: DateComponents(year: 2026, month: 4, day: 22))!
    return CalendarSectionPreviewContainer(birthDate: birthDate)
        .environment(\.theme, .zzippu)
}

#Preview("DashboardCalendarSection — dark") {
    let birthDate = Calendar.kst.date(from: DateComponents(year: 2026, month: 4, day: 22))!
    return CalendarSectionPreviewContainer(birthDate: birthDate)
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
