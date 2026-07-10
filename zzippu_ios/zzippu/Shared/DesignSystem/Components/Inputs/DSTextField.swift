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
            .font(theme.typography.callout)   // 16pt — iOS 자동줌 방지
            .focused($isFocused)
            .frame(height: theme.component.input.height)
            .padding(.horizontal, theme.component.input.paddingX)
            .background(theme.color.surface.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.component.input.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.component.input.radius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
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

    private var borderColor: Color {
        if case .error = state { return theme.color.statusDangerSolid.color }
        if isFocused           { return theme.color.primary.color }
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
