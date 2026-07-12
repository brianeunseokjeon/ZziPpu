// Shared/DesignSystem/Components/Overlays/DSBottomSheet.swift
// .dsBottomSheet(isPresented:) { } ViewModifier.
// 네이티브 presentationDetents + presentationCornerRadius (iOS 16+) 기반.

import SwiftUI

// MARK: - BottomSheet Options

public struct DSBottomSheetOptions {
    public var title:        String?
    public var showGrabber:  Bool
    public var detents:      Set<PresentationDetent>

    public init(
        title:       String? = nil,
        showGrabber: Bool = true,
        detents:     Set<PresentationDetent> = [.medium, .large]
    ) {
        self.title       = title
        self.showGrabber = showGrabber
        self.detents     = detents
    }
}

// MARK: - DSBottomSheetModifier

private struct DSBottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let options:      DSBottomSheetOptions
    let sheetContent: () -> SheetContent

    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                DSBottomSheetContainer(
                    options:      options,
                    content:      sheetContent
                )
                .presentationDetents(options.detents)
                .presentationCornerRadius(theme.radius.sheet)
                .presentationDragIndicator(options.showGrabber ? .visible : .hidden)
                .environment(\.theme, theme)
            }
    }
}

// MARK: - DSBottomSheetContainer

private struct DSBottomSheetContainer<Content: View>: View {
    let options:     DSBottomSheetOptions
    let content:     () -> Content

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // Optional header — X 닫기 버튼 없음(grabber+스와이프+스크림 탭으로 충분, 웹 동일).
            if let title = options.title {
                HStack {
                    Text(title)
                        .font(theme.typography.title)   // R4(웹정합): 시트 타이틀 text-lg(18) semibold
                        .foregroundStyle(theme.color.textPrimary.color)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, theme.space.componentPaddingX)
                .padding(.vertical, theme.space.componentPaddingY)

                Divider()
                    .foregroundStyle(theme.color.divider.color)
            }

            // Content — 시트 표준 패딩(웹 px-5=20). 헤더 유무에 따라 top만 달라짐.
            // 피처는 시트 콘텐츠 안에서 다시 .padding()을 걸지 말 것(중복 패딩 방지).
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.space.cardPadding)              // 20 — 좌우
                .padding(.top, options.title != nil
                         ? theme.space.componentPaddingY                    // 12 — 헤더와 간격
                         : theme.space.cardPadding)                         // 20 — grabber 아래 여백
                .padding(.bottom, theme.space.cardPadding)                  // 20 — 하단 통일
        }
        .background(theme.color.surface.color)
    }
}

// MARK: - View Extension

extension View {
    /// 네이티브 시트 기반 바텀시트.
    /// ```swift
    /// .dsBottomSheet(isPresented: $show) { MyContent() }
    /// .dsBottomSheet(isPresented: $show, options: .init(title: "제목")) { MyContent() }
    /// ```
    public func dsBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        options:     DSBottomSheetOptions = .init(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(DSBottomSheetModifier(
            isPresented:  isPresented,
            options:      options,
            sheetContent: content
        ))
    }
}

// MARK: - Preview

private struct BottomSheetPreview: View {
    @State private var showDefault  = false
    @State private var showWithTitle = false

    var body: some View {
        VStack(spacing: 16) {
            Button("시트 열기 (기본)") { showDefault = true }
                .buttonStyle(.ds(.primary))
            Button("시트 열기 (타이틀+닫기)") { showWithTitle = true }
                .buttonStyle(.ds(.secondary))
        }
        .padding()
        .dsBottomSheet(isPresented: $showDefault) {
            VStack(spacing: 12) {
                Text("바텀시트 콘텐츠")
                    .font(Theme.zzippu.typography.body)
            }
        }
        .dsBottomSheet(
            isPresented: $showWithTitle,
            options: .init(title: "기록 추가", detents: [.medium])
        ) {
            VStack(spacing: 12) {
                Text("여기에 폼이 들어갑니다")
                    .font(Theme.zzippu.typography.body)
            }
        }
        .environment(\.theme, .zzippu)
    }
}

#Preview("DSBottomSheet") {
    BottomSheetPreview()
}
