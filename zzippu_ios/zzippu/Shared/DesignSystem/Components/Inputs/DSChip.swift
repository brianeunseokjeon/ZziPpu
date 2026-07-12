// Shared/DesignSystem/Components/Inputs/DSChip.swift
// DSChip (선택형 칩) + QuickChipsRow (프리셋 행).

import SwiftUI

// MARK: - DSChip Variant

public enum DSChipVariant {
    case selectable  // 선택 토글
    case `static`    // 태그 (읽기 전용)
    case quick       // 빠른 입력 프리셋
}

// MARK: - DSChip

/// 선택형 칩. 높이 44pt (초단위 입력 오탭 방지).
public struct DSChip: View {
    public let label:      String
    public var isSelected: Bool
    public var variant:    DSChipVariant
    /// 도메인 색 칩에 쓸 커스텀 tint (nil이면 semantic primaryTint 사용)
    var tint: DynamicColor?
    public var onTap:      (() -> Void)?

    init(
        label:      String,
        isSelected: Bool = false,
        variant:    DSChipVariant = .selectable,
        tint:       DynamicColor? = nil,
        onTap:      (() -> Void)? = nil
    ) {
        self.label      = label
        self.isSelected = isSelected
        self.variant    = variant
        self.tint       = tint
        self.onTap      = onTap
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        Button(action: { onTap?() }) {
            Text(label)
                .font(theme.typography.captionStrong)
                .foregroundStyle(fgColor)
                .frame(height: theme.component.chip.height)
                .padding(.horizontal, theme.component.chip.paddingX)
                .background(bgColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(theme.color.borderStrong.color, lineWidth: showBorder ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .disabled(variant == .static)
    }

    // MARK: Colors

    private var bgColor: Color {
        if isSelected {
            // 웹정합: quick 프리셋 선택 = solid 파란 채움(bg-blue-500). 그 외(selectable)는 tint.
            if variant == .quick { return theme.color.statusInfoSolid.color }
            return (tint ?? theme.color.primaryTint).color
        }
        // 웹 미선택 프리셋: bg-white border-gray-200. selectable: surfaceSunken 유지.
        return variant == .quick ? theme.color.surface.color : theme.color.surfaceSunken.color
    }

    private var fgColor: Color {
        if isSelected {
            // quick solid 선택 시 흰 글자.
            if variant == .quick { return theme.color.onPrimary.color }
            return theme.color.primary.color
        }
        return theme.color.textSecondary.color
    }

    /// quick 미선택 칩엔 웹처럼 gray-200 테두리.
    private var showBorder: Bool { variant == .quick && !isSelected }
}

// MARK: - QuickChipsRow

/// 빠른 입력 프리셋 칩 행. 단일 선택.
public struct QuickChipsRow: View {
    public let options:   [String]
    @Binding public var selection: String?

    public init(options: [String], selection: Binding<String?>) {
        self.options    = options
        self._selection = selection
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    DSChip(
                        label:      option,
                        isSelected: selection == option,
                        variant:    .quick,
                        onTap:      { selection = selection == option ? nil : option }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Preview

private struct DSChipPreview: View {
    @State private var selected: String? = "120ml"
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                DSChip(label: "분유",  isSelected: true)
                DSChip(label: "모유",  isSelected: false)
                DSChip(label: "이유식", isSelected: false)
            }
            QuickChipsRow(
                options: ["100ml", "120ml", "150ml", "180ml"],
                selection: $selected
            )
        }
        .padding()
        .environment(\.theme, .zzippu)
    }
}

#Preview("DSChip") {
    DSChipPreview()
}
