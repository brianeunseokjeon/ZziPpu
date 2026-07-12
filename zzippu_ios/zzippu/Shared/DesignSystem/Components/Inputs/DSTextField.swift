// Shared/DesignSystem/Components/Inputs/DSTextField.swift
// 라벨 + 텍스트필드 + 헬퍼/에러 텍스트 조합.

import SwiftUI

// MARK: - DSTextFieldState

public enum DSTextFieldState {
    case normal
    case focused
    case error(String)  // 에러 메시지 포함
    case disabled
}

// MARK: - DSTextField

public struct DSTextField: View {
    public let label:        String?
    public let placeholder:  String
    @Binding public var text: String
    public var state:        DSTextFieldState
    public var keyboardType: UIKeyboardType
    public var isSecure:     Bool

    @FocusState private var isFocused: Bool
    @Environment(\.theme) private var theme

    public init(
        label:       String? = nil,
        placeholder: String = "",
        text:        Binding<String>,
        state:       DSTextFieldState = .normal,
        keyboardType: UIKeyboardType = .default,
        isSecure:    Bool = false
    ) {
        self.label        = label
        self.placeholder  = placeholder
        self._text        = text
        self.state        = state
        self.keyboardType = keyboardType
        self.isSecure     = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            // Label
            if let label {
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
            }

            // Field
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(theme.typography.input)   // 16pt 고정 — iOS 자동줌 방지
            .focused($isFocused)
            .frame(height: theme.component.input.height)
            .padding(.horizontal, theme.component.input.paddingX)
            // R2(웹정합): 아웃라인형 — 웹 bg-white + border-gray-200 상시. focus 시 primary 링.
            .background(fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: theme.component.input.radius, style: .continuous))
            .overlay(
                // idle에도 1px 회색 테두리 상시 표시, focus/error 시 primary/danger 링(1.5).
                RoundedRectangle(cornerRadius: theme.component.input.radius, style: .continuous)
                    .stroke(borderColor, lineWidth: showRing ? 1.5 : 1)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1)

            // Helper / Error
            if case .error(let msg) = state {
                Text(msg)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.statusDangerFg.color)
            }
        }
    }

    // MARK: Border color

    private var isError: Bool {
        if case .error = state { return true }
        return false
    }

    /// 링(테두리)은 focus 또는 error 상태에서만 표시.
    private var showRing: Bool { isFocused || isError }

    private var fieldBg: Color {
        // 아웃라인형: 항상 흰 표면. focus 시 옅은 primaryTint로 강조.
        isFocused ? theme.color.primaryTint.color : theme.color.surface.color
    }

    private var borderColor: Color {
        if isError   { return theme.color.statusDangerSolid.color }
        if isFocused { return theme.color.primary.color }
        // idle: 웹 border-gray-200 상시.
        return theme.color.borderStrong.color
    }

    private var isDisabled: Bool {
        if case .disabled = state { return true }
        return false
    }
}

// MARK: - Preview

private struct DSTextFieldPreview: View {
    @State private var text1 = ""
    @State private var text2 = "brian@example.com"
    @State private var text3 = "too short"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DSTextField(label: "이메일", placeholder: "이메일 주소 입력", text: $text1)
                DSTextField(label: "이메일 (입력됨)", placeholder: "", text: $text2)
                DSTextField(
                    label: "이메일 (에러)",
                    placeholder: "이메일 주소 입력",
                    text: $text3,
                    state: .error("유효한 이메일 주소를 입력하세요.")
                )
                DSTextField(
                    label: "비밀번호 (비활성)",
                    placeholder: "비밀번호",
                    text: .constant(""),
                    state: .disabled
                )
            }
            .padding(16)
        }
        .environment(\.theme, .zzippu)
    }
}

#Preview("DSTextField") {
    DSTextFieldPreview()
}
