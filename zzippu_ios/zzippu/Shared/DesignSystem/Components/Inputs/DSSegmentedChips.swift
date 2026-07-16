// Shared/DesignSystem/Components/Inputs/DSSegmentedChips.swift
// 균등폭 단일선택 세그먼트 칩 행.
// DSChip(.selectable)을 각 옵션에 .frame(maxWidth:.infinity)로 래핑 → 한 행을 N등분.
// 가로스크롤 없음. Spacer 없음. compact 시 칩 간격 xs(4) + 라벨 minimumScaleFactor(0.85).

import SwiftUI

// MARK: - DSSegmentedChips

/// 한 행을 N등분 균등폭으로 채우는 단일선택 세그먼트.
/// 좌우 바깥 여백은 호출부(screenPaddingX 16)가 담당하고, 컴포넌트는 칩 사이 간격만 책임진다.
/// 같은 값 재탭 시 selection → nil 토글(기존 ChipRow 동작 유지).
struct DSSegmentedChips<Option: Hashable>: View {
    /// 표시 순서대로 나열할 옵션 배열
    let options: [Option]
    /// 단일선택 바인딩. 재탭 시 nil 토글.
    @Binding var selection: Option?
    /// 옵션 → 라벨 텍스트 클로저
    let label: (Option) -> String
    /// 옵션별 커스텀 tint (nil이면 semantic primaryTint 사용)
    var tint: ((Option) -> DynamicColor?)?
    /// 칩 사이 간격 (기본 sm=8, compact=xs=4)
    var spacing: CGFloat
    /// true면 칩 간격 xs(4) + 라벨 minimumScaleFactor(0.85) 적용 — 5칩(대변색) 대응
    var compact: Bool

    @Environment(\.theme) private var theme

    init(
        options:   [Option],
        selection: Binding<Option?>,
        label:     @escaping (Option) -> String,
        tint:      ((Option) -> DynamicColor?)? = nil,
        spacing:   CGFloat? = nil,
        compact:   Bool = false
    ) {
        self.options    = options
        self._selection = selection
        self.label      = label
        self.tint       = tint
        self.compact    = compact
        // spacing 미지정 시: compact면 xs(4), 일반이면 sm(8) — 초기화 시점에 theme 접근 불가라
        // nil placeholder 저장 후 body에서 대입한다.
        self.spacing    = spacing ?? -1   // sentinel → body에서 덮어씀
    }

    public var body: some View {
        let effectiveSpacing: CGFloat = spacing == -1
            ? (compact ? theme.space.xs : theme.space.sm)
            : spacing

        HStack(spacing: effectiveSpacing) {
            ForEach(options, id: \.self) { option in
                chipView(for: option)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - 개별 칩

    @ViewBuilder
    private func chipView(for option: Option) -> some View {
        let isSelected = selection == option
        let chipTint   = tint?(option)

        Button {
            selection = isSelected ? nil : option
        } label: {
            Text(label(option))
                .font(theme.typography.captionStrong)
                .lineLimit(1)
                .minimumScaleFactor(compact ? 0.85 : 1.0)
                .foregroundStyle(isSelected
                    ? theme.color.primary.color
                    : theme.color.textSecondary.color)
                .frame(maxWidth: .infinity)
                .frame(height: theme.component.chip.height)   // 44pt 고정 (HIG 최소 터치)
                .background(
                    (isSelected
                        ? (chipTint ?? theme.color.primaryTint).color
                        : theme.color.surfaceSunken.color)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("DSSegmentedChips — 3칩 (라이트)") {
    struct Preview3: View {
        @State private var sel: String? = "보통"
        @Environment(\.theme) private var theme
        var body: some View {
            VStack(spacing: theme.space.md) {
                Text("양 (3칩)")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DSSegmentedChips(
                    options:   ["적게", "보통", "많이"],
                    selection: $sel,
                    label:     { $0 }
                )
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .environment(\.theme, .zzippu)
        }
    }
    return Preview3().environment(\.theme, .zzippu)
}

#Preview("DSSegmentedChips — 5칩 compact (라이트)") {
    struct Preview5: View {
        @State private var sel: String? = "황금똥"
        @Environment(\.theme) private var theme
        var body: some View {
            VStack(spacing: theme.space.md) {
                Text("대변 색 (5칩 compact)")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DSSegmentedChips(
                    options:   ["황금똥", "초록색", "검은색", "붉은색", "보통"],
                    selection: $sel,
                    label:     { $0 },
                    compact:   true
                )
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .environment(\.theme, .zzippu)
        }
    }
    return Preview5().environment(\.theme, .zzippu)
}

#Preview("DSSegmentedChips — 3칩 (다크)") {
    struct Preview3Dark: View {
        @State private var sel: String? = nil
        @Environment(\.theme) private var theme
        var body: some View {
            VStack(spacing: theme.space.md) {
                Text("질감 (3칩 다크)")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DSSegmentedChips(
                    options:   ["묽음", "보통", "찰흙"],
                    selection: $sel,
                    label:     { $0 }
                )
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding()
            .background(Color.black)
        }
    }
    return Preview3Dark()
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}

#Preview("DSSegmentedChips — 5칩 compact (다크)") {
    struct Preview5Dark: View {
        @State private var sel: String? = "초록색"
        @Environment(\.theme) private var theme
        var body: some View {
            VStack(spacing: theme.space.md) {
                Text("대변 색 (5칩 compact 다크)")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DSSegmentedChips(
                    options:   ["황금똥", "초록색", "검은색", "붉은색", "보통"],
                    selection: $sel,
                    label:     { $0 },
                    compact:   true
                )
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding()
            .background(Color.black)
        }
    }
    return Preview5Dark()
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
