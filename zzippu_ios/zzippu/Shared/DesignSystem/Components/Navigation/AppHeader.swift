// Shared/DesignSystem/Components/Navigation/AppHeader.swift
// 앱 헤더: [아바타][이름/나이]  ·····  [< 날짜 >]
// sticky, safe-area 상단. 날짜 네비(어제/오늘/다음, 오늘이면 다음 비활성).
// BabyAvatar + DSIconButton 재사용.
// baby 파라미터: DesignSystem 내부 표시용 struct (도메인 엔티티 비의존).

import SwiftUI

// MARK: - AppHeaderBaby (DS 내부 표시용 뷰 모델 구조체)

/// DesignSystem 순수성 유지: 도메인 Baby 엔티티 직접 의존 금지.
/// 피처가 자신의 Baby 엔티티 → AppHeaderBaby 로 변환해 주입.
public struct AppHeaderBaby {
    public let name:        String
    public let birthDate:   Date
    public let gender:      BabyGender
    public let photoURL:    URL?

    public init(
        name:      String,
        birthDate: Date,
        gender:    BabyGender = .unknown,
        photoURL:  URL? = nil
    ) {
        self.name      = name
        self.birthDate = birthDate
        self.gender    = gender
        self.photoURL  = photoURL
    }
}

// MARK: - AppHeader

public struct AppHeader: View {
    public let baby:         AppHeaderBaby
    @Binding public var selectedDate: Date
    public let onDateChange: (Date) -> Void

    public init(
        baby:         AppHeaderBaby,
        selectedDate: Binding<Date>,
        onDateChange: @escaping (Date) -> Void
    ) {
        self.baby          = baby
        self._selectedDate = selectedDate
        self.onDateChange  = onDateChange
    }

    @Environment(\.theme) private var theme

    private var isToday: Bool {
        Calendar.kst.isDateInToday(selectedDate)
    }

    private var ageText: String {
        // 웹 getAgeDays()와 일치: 태어난 날 당일 = 생후 1일.
        // 날짜(자정) 기준으로 일수를 세고 +1.
        let cal = Calendar.kst
        let birth = cal.startOfDay(for: baby.birthDate)
        let today = cal.startOfDay(for: Date())
        let days = (cal.dateComponents([.day], from: birth, to: today).day ?? 0) + 1
        return "생후 \(days)일"
    }

    private var dateText: String {
        // 웹정합: 웹 헤더는 오늘도 "M월 d일"을 그대로 노출(formatDate). "오늘" 치환 폐기.
        // 요일(E) 병기 — 예: "7월 12일 (일)". ko_KR에서 E=일/월/…
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.timeZone = .kst
        fmt.dateFormat = "M월 d일 (E)"
        return fmt.string(from: selectedDate)
    }

    public var body: some View {
        HStack(spacing: theme.space.stackGapMd) {
            // Avatar + name/age
            BabyAvatar(photoURL: baby.photoURL, gender: baby.gender, size: .sm)

            VStack(alignment: .leading, spacing: 1) {
                // R4(웹정합): 아기이름 웹 text-base(16) bold.
                Text(baby.name)
                    .font(theme.typography.headlineStrong)
                    .foregroundStyle(theme.color.textPrimary.color)
                // 웹정합: 나이 텍스트 gray-400(textTertiary).
                Text(ageText)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textTertiary.color)
            }

            Spacer()

            // Date navigation
            HStack(spacing: 0) {
                // 웹정합: chevron 16pt(w-4 h-4).
                DSIconButton(systemName: "chevron.left", iconSize: 16) {
                    let prev = Calendar.kst.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    selectedDate = prev
                    onDateChange(prev)
                }

                // 날짜 라벨 text-sm(14) medium(=body). 요일 병기로 폭 증가 → min-w 130(전환 시 흔들림 방지).
                Text(dateText)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.color.textPrimary.color)
                    .frame(minWidth: 130, alignment: .center)

                DSIconButton(systemName: "chevron.right", iconSize: 16) {
                    guard !isToday else { return }
                    let next = Calendar.kst.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    selectedDate = next
                    onDateChange(next)
                }
                .opacity(isToday ? 0.3 : 1.0)
                .disabled(isToday)
            }
        }
        .padding(.horizontal, theme.space.screenPaddingX)
        .frame(height: 56)
        .background(theme.color.surface.color)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.color.divider.color)
                .frame(height: 1)
        }
    }
}

// MARK: - Preview

private struct AppHeaderPreview: View {
    @State private var date = Date()

    let baby = AppHeaderBaby(
        name:      "아람이",
        birthDate: Calendar.kst.date(byAdding: .day, value: -42, to: Date()) ?? Date(),
        gender:    .male
    )

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(baby: baby, selectedDate: $date, onDateChange: { _ in })
            Spacer()
        }
        .environment(\.theme, .zzippu)
    }
}

#Preview("AppHeader") {
    AppHeaderPreview()
}
