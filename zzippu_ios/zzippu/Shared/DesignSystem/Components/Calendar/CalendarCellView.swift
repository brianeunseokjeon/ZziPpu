// Shared/DesignSystem/Components/Calendar/CalendarCellView.swift
// 달력 날짜 셀 — 색 없는 DTO 수신, Domain 비의존.
// kind → theme 색 매핑은 이 파일 내에서 처리.

import SwiftUI

// MARK: - CalendarCellDTO

/// DS 컴포넌트가 받는 색 없는 DTO (Domain 엔티티 비의존).
struct CalendarCellDTO {
    let dateNumber: Int
    let volumeText: String?           // 수유량 숫자 (nil = 공란)
    let isToday: Bool
    let isOutside: Bool               // 넘침칸
    let isFuture: Bool
    let eventBadges: [EventBadgeDTO]  // 도트+라벨 (최대 1개, 초과는 +N)
    let underbars: [UnderbarDTO]      // 언더바 (최대 2겹)
    let accessibilityLabel: String
}

struct EventBadgeDTO {
    let label: String             // "2차"
    let kind: CalendarDecorationKind
}

struct UnderbarDTO {
    let spanRole: SpanRole
    let kind: CalendarDecorationKind
}

// MARK: - CalendarCellView

struct CalendarCellView: View {

    let dto: CalendarCellDTO
    let isWeekend: Bool
    let weekdayIndex: Int  // 0=일, 6=토

    @Environment(\.theme) private var theme

    var body: some View {
        ZStack(alignment: .bottom) {
            // 언더바 (셀 최하단, z=1)
            underbarLayer

            // 날짜+수유량 스택 (z=기준)
            VStack(spacing: 2) {
                // 날짜 숫자 (오늘 원형 강조)
                dateNumberView

                // 총 수유량 숫자
                volumeView
            }
            .padding(.top, theme.space.xs)
            .padding(.horizontal, 2)
            .padding(.bottom, 6)   // 언더바 자리 확보

            // 검진 도트+라벨 오버레이 (우상단, z=최상)
            eventBadgeOverlay
        }
        .frame(maxWidth: .infinity)
        .frame(height: theme.component.calendarCell.minHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dto.accessibilityLabel)
    }

    // MARK: - Sub Views

    private var dateNumberView: some View {
        ZStack {
            if dto.isToday {
                Circle()
                    .fill(theme.color.primary.color)
                    .frame(
                        width:  theme.component.calendarCell.todayCircle,
                        height: theme.component.calendarCell.todayCircle
                    )
            }
            Text("\(dto.dateNumber)")
                .font(dto.isToday ? theme.typography.captionStrong : theme.typography.caption)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .foregroundStyle(dateNumberColor)
        }
    }

    private var dateNumberColor: Color {
        if dto.isOutside { return theme.color.textTertiary.color }
        if dto.isToday   { return theme.color.onPrimary.color }
        // 주말 60% 불투명 색상 (요일헤더보다 약하게)
        if weekdayIndex == 0 { return theme.color.statusDangerFg.color.opacity(0.6) }
        if weekdayIndex == 6 { return theme.color.statusInfoFg.color.opacity(0.6) }
        return theme.color.textPrimary.color
    }

    private var volumeView: some View {
        Group {
            if let text = dto.volumeText, !dto.isOutside {
                Text(text)
                    .font(theme.typography.mono)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .foregroundStyle(theme.color.textStrong.color)
            } else {
                // 공란 — 높이 보존용 투명 텍스트
                Text(" ")
                    .font(theme.typography.mono)
            }
        }
    }

    @ViewBuilder
    private var eventBadgeOverlay: some View {
        if !dto.eventBadges.isEmpty && !dto.isOutside {
            let badge = dto.eventBadges[0]
            let overflow = dto.eventBadges.count - 1

            HStack(spacing: 1) {
                // 도트
                Circle()
                    .fill(checkupColor)
                    .frame(
                        width:  theme.component.calendarCell.eventDotSize,
                        height: theme.component.calendarCell.eventDotSize
                    )
                // 라벨
                Text(overflow > 0 ? "+\(overflow + 1)" : badge.label)
                    .font(theme.typography.label)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(checkupColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 2)
            .padding(.trailing, 2)
        }
    }

    @ViewBuilder
    private var underbarLayer: some View {
        if !dto.underbars.isEmpty && !dto.isOutside {
            VStack(spacing: 1) {
                ForEach(Array(dto.underbars.enumerated()), id: \.offset) { _, bar in
                    underbarShape(role: bar.spanRole)
                        .fill(checkupColor)
                        .frame(height: theme.component.calendarCell.underbarHeight)
                        .padding(.horizontal, 3)
                }
            }
        }
    }

    private func underbarShape(role: SpanRole) -> some Shape {
        UnderbarShape(spanRole: role)
    }

    // kind → theme 색 매핑 (DS는 Domain 비의존 — kind 값만 받아 View에서 변환)
    private var checkupColor: Color {
        theme.color.domainCheckupSolid.color
    }
}

// MARK: - UnderbarShape

/// 언더바 shape — spanRole에 따라 캡슐 끝 처리.
struct UnderbarShape: Shape {
    let spanRole: SpanRole

    func path(in rect: CGRect) -> Path {
        let r = rect.height / 2
        var path = Path()
        let leftRound  = (spanRole == .start || spanRole == .single)
        let rightRound = (spanRole == .end   || spanRole == .single)

        path.addRoundedRect(
            in: rect,
            cornerRadii: RectangleCornerRadii(
                topLeading:     leftRound  ? r : 0,
                bottomLeading:  leftRound  ? r : 0,
                bottomTrailing: rightRound ? r : 0,
                topTrailing:    rightRound ? r : 0
            )
        )
        return path
    }
}

// MARK: - Preview

#Preview("CalendarCellView") {
    let dtos: [CalendarCellDTO] = [

        // 평상
        CalendarCellDTO(
            dateNumber: 8, volumeText: "650", isToday: false,
            isOutside: false, isFuture: false,
            eventBadges: [], underbars: [],
            accessibilityLabel: "7월 8일. 총 수유 650밀리리터."
        ),
        // 오늘 + 검진 시작일
        CalendarCellDTO(
            dateNumber: 12, volumeText: "720", isToday: true,
            isOutside: false, isFuture: false,
            eventBadges: [EventBadgeDTO(label: "2차", kind: .checkupWindow)],
            underbars: [UnderbarDTO(spanRole: .start, kind: .checkupWindow)],
            accessibilityLabel: "7월 12일, 오늘. 총 수유 720밀리리터. 2차 검진 시작일."
        ),
        // 검진 기간 중(미래)
        CalendarCellDTO(
            dateNumber: 25, volumeText: nil, isToday: false,
            isOutside: false, isFuture: true,
            eventBadges: [],
            underbars: [UnderbarDTO(spanRole: .middle, kind: .checkupWindow)],
            accessibilityLabel: "8월 25일. 2차 검진 기간."
        ),
        // 넘침칸
        CalendarCellDTO(
            dateNumber: 1, volumeText: nil, isToday: false,
            isOutside: true, isFuture: false,
            eventBadges: [], underbars: [],
            accessibilityLabel: "이번 달 아님."
        ),
        // 수유량만
        CalendarCellDTO(
            dateNumber: 5, volumeText: "520", isToday: false,
            isOutside: false, isFuture: false,
            eventBadges: [], underbars: [],
            accessibilityLabel: "7월 5일. 총 수유 520밀리리터."
        ),
        // 기록 없음
        CalendarCellDTO(
            dateNumber: 3, volumeText: nil, isToday: false,
            isOutside: false, isFuture: false,
            eventBadges: [], underbars: [],
            accessibilityLabel: "7월 3일. 수유 기록 없음."
        ),
    ]

    return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
        ForEach(Array(dtos.enumerated()), id: \.offset) { idx, dto in
            CalendarCellView(dto: dto, isWeekend: idx == 0 || idx == 6, weekdayIndex: idx % 7)
        }
    }
    .padding()
    .environment(\.theme, .zzippu)
}

#Preview("CalendarCellView — dark") {
    let dto = CalendarCellDTO(
        dateNumber: 22, volumeText: "820", isToday: false,
        isOutside: false, isFuture: false,
        eventBadges: [EventBadgeDTO(label: "3차", kind: .checkupWindow)],
        underbars: [UnderbarDTO(spanRole: .start, kind: .checkupWindow)],
        accessibilityLabel: "8월 22일. 총 수유 820밀리리터. 3차 검진 시작일."
    )
    return CalendarCellView(dto: dto, isWeekend: false, weekdayIndex: 3)
        .padding()
        .frame(width: 80)
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
