// Shared/DesignSystem/Components/Inputs/DSNumberStepper.swift
// [−] [값] [+] + 직접입력. 범위 clamp·step 주입. 버튼 44.
// value: title typography.

import SwiftUI

// MARK: - DSNumberStepper

public struct DSNumberStepper: View {
    @Binding public var value: Int
    public let range: ClosedRange<Int>
    public let step:  Int
    public var unit:  String?  // 옵션 단위 표시 (e.g. "ml")

    public init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...9999,
        step:  Int = 1,
        unit:  String? = nil
    ) {
        self._value = value
        self.range  = range
        self.step   = step
        self.unit   = unit
    }

    @Environment(\.theme) private var theme
    @State private var editingText: String? = nil
    @FocusState private var isFocused: Bool

    public var body: some View {
        HStack(spacing: 0) {
            // Minus button
            stepButton(systemName: "minus") {
                let next = value - step
                value = max(range.lowerBound, next)
            }
            .disabled(value <= range.lowerBound)

            // Value display / direct input
            ZStack {
                if let text = editingText {
                    TextField("", text: Binding(
                        get: { text },
                        set: { editingText = $0 }
                    ))
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.center)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.color.textPrimary.color)
                    .frame(minWidth: 60)
                    .onSubmit { commitEdit() }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { commitEdit() }
                    }
                } else {
                    HStack(spacing: 2) {
                        Text("\(value)")
                            .font(theme.typography.title)
                            .foregroundStyle(theme.color.textPrimary.color)
                        if let unit {
                            Text(unit)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.color.textSecondary.color)
                        }
                    }
                    .frame(minWidth: 60)
                    .onTapGesture { beginEdit() }
                }
            }
            .frame(minWidth: 60, minHeight: 44)

            // Plus button
            stepButton(systemName: "plus") {
                let next = value + step
                value = min(range.upperBound, next)
            }
            .disabled(value >= range.upperBound)
        }
        .background(
            RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                .fill(theme.color.surfaceSunken.color)
        )
    }

    // MARK: Step button

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.color.primary.color)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: Edit helpers

    private func beginEdit() {
        editingText = "\(value)"
        isFocused   = true
    }

    private func commitEdit() {
        if let text = editingText, let parsed = Int(text) {
            value = max(range.lowerBound, min(range.upperBound, parsed))
        }
        editingText = nil
        isFocused   = false
    }
}

// MARK: - Preview

private struct DSNumberStepperPreview: View {
    @State private var ml  = 120
    @State private var min = 10

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("수유량").font(Theme.zzippu.typography.captionStrong)
                DSNumberStepper(value: $ml, range: 0...500, step: 10, unit: "ml")
            }
            VStack(spacing: 8) {
                Text("수유 시간").font(Theme.zzippu.typography.captionStrong)
                DSNumberStepper(value: $min, range: 0...60, step: 1, unit: "분")
            }
        }
        .padding()
        .environment(\.theme, .zzippu)
    }
}

#Preview("DSNumberStepper") {
    DSNumberStepperPreview()
}
