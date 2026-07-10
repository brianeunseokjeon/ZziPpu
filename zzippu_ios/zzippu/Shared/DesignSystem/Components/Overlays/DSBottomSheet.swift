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
                    isPresented:  $isPresented,
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
    @Binding var isPresented: Bool
    let content:     () -> Content

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // Optional header
            if let title = options.title {
                HStack {
                    Text(title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.color.textPrimary.color)
                    Spacer()
                    DSIconButton(systemName: "xmark") {
                        isPresented = false
                    }
                }
                .padding(.horizontal, theme.space.componentPaddingX)
                .padding(.vertical, theme.space.componentPaddingY)

                Divider()
                    .foregroundStyle(theme.color.divider.color)
            }

            // Content
            content()
                .padding(.bottom, theme.space.md)  // safe-area 보완
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
                    .padding()
            }
        }
        .dsBottomSheet(
            isPresented: $showWithTitle,
            options: .init(title: "기록 추가", detents: [.medium])
        ) {
            VStack(spacing: 12) {
                Text("여기에 폼이 들어갑니다")
                    .font(Theme.zzippu.typography.body)
                    .padding()
            }
        }
        .environment(\.theme, .zzippu)
    }
}

#Preview("DSBottomSheet") {
    BottomSheetPreview()
}
