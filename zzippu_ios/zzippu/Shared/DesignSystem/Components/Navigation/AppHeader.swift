// Shared/DesignSystem/Components/Navigation/AppHeader.swift
// 앱 헤더: [아바타][이름/나이]  ·····  [< 날짜 >]
// sticky, safe-area 상단. 날짜 네비(어제/오늘/다음, 오늘이면 다음 비활성).
// BabyAvatar + DSIconButton 재사용.
// baby 파라미터: DesignSystem 내부 표시용 struct (도메인 엔티티 비의존).

import SwiftUI
import UIKit

// MARK: - AppHeaderBaby (DS 내부 표시용 뷰 모델 구조체)

/// DesignSystem 순수성 유지: 도메인 Baby 엔티티 직접 의존 금지.
/// 피처가 자신의 Baby 엔티티 → AppHeaderBaby 로 변환해 주입.
public struct AppHeaderBaby {
    public let name:        String
    public let birthDate:   Date
    public let gender:      BabyGender
    public let photoURL:    URL?
    /// 기기-로컬 대표 이미지(서버 미업로드). 있으면 아바타 최우선.
    public let localImage:  UIImage?

    public init(
        name:       String,
        birthDate:  Date,
        gender:     BabyGender = .unknown,
        photoURL:   URL? = nil,
        localImage: UIImage? = nil
    ) {
        self.name       = name
        self.birthDate  = birthDate
        self.gender     = gender
        self.photoURL   = photoURL
        self.localImage = localImage
    }
}

// MARK: - AppHeader

public struct AppHeader: View {
    public let baby:         AppHeaderBaby
    @Binding public var selectedDate: Date
    public let onDateChange: (Date) -> Void
    /// 생일 이전 이동 허용(기본 false → 생일에서 ◀ 정지). 홈에서 “그 이전 보기” 선택 시 true.
    public let allowBeforeBirth: Bool

    public init(
        baby:             AppHeaderBaby,
        selectedDate:     Binding<Date>,
        allowBeforeBirth: Bool = false,
        onDateChange:     @escaping (Date) -> Void
    ) {
        self.baby             = baby
        self._selectedDate    = selectedDate
        self.allowBeforeBirth = allowBeforeBirth
        self.onDateChange     = onDateChange
    }

    @Environment(\.theme) private var theme

    private var isToday: Bool {
        Calendar.kst.isDateInToday(selectedDate)
    }

    /// 생일 하한 도달 여부(◀ 비활성 조건). allowBeforeBirth면 항상 false.
    private var isAtBirthFloor: Bool {
        guard !allowBeforeBirth else { return false }
        let cal = Calendar.kst
        return cal.startOfDay(for: selectedDate) <= cal.startOfDay(for: baby.birthDate)
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
        fmt.locale = .current
        fmt.timeZone = .kst
        fmt.setLocalizedDateFormatFromTemplate("MMMMdEEE")   // 기기 언어. ko "7월 12일 (일)"
        return fmt.string(from: selectedDate)
    }

    public var body: some View {
        HStack(spacing: theme.space.stackGapSm) {   // 8 — 웹 좌측 gap-2(아바타↔이름)
            // Avatar + name/age
            BabyAvatar(photoURL: baby.photoURL, localImage: baby.localImage, gender: baby.gender, size: .sm)

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
                // 웹정합: chevron 웹 w-4(16px) lucide 얇은 선. SF 심볼은 같은 pt에서 더 두꺼워 보여
                // 시각 크기를 맞추려 12pt로 축소(색 gray-500=textSecondary는 DSIconButton 기본).
                DSIconButton(systemName: "chevron.left", iconSize: 12) {
                    guard !isAtBirthFloor else { return }
                    let prev = Calendar.kst.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    selectedDate = prev
                    onDateChange(prev)
                }
                .opacity(isAtBirthFloor ? 0.3 : 1.0)
                .disabled(isAtBirthFloor)

                // 웹정합: 날짜 text-sm(14) medium(=body) + gray-700(textStrong). min-w 110(웹 동일, 흔들림 방지).
                Text(dateText)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.color.textStrong.color)
                    .frame(minWidth: 110, alignment: .center)

                DSIconButton(systemName: "chevron.right", iconSize: 12) {
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
