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
            // Optional header(고정) — ScrollView 밖에 둬서 스크롤해도 제목이 항상 보인다.
            // X 닫기 버튼 없음(grabber+스와이프+스크림 탭으로 충분, 웹 동일).
            if let title = options.title {
                HStack {
                    Text(title)
                        .font(theme.typography.title)   // R4(웹정합): 시트 타이틀 text-lg(18) semibold
                        .foregroundStyle(theme.color.textPrimary.color)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, theme.space.componentPaddingX)
                .padding(.bottom, theme.space.stackGapMd)                   // 12 — 제목 아래 간격

                Divider()
                    .foregroundStyle(theme.color.divider.color)
            }

            // Content(스크롤) — detent 높이보다 콘텐츠가 커도 잘리지 않고 스크롤된다.
            // 피처는 시트 콘텐츠 안에서 다시 .padding()을 걸지 말 것(중복 패딩 방지).
            ScrollView {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // 타이틀(componentPaddingX)과 동일하게 → 콘텐츠가 타이틀 아이콘 x에 왼쪽정렬.
                    .padding(.horizontal, theme.space.componentPaddingX)     // 16 — 타이틀과 통일
                    .padding(.top, options.title != nil
                             ? theme.space.stackGapMd                       // 12 — 헤더와 간격
                             : 0)
                    .padding(.bottom, theme.space.cardPadding)              // 20 — 하단 통일
            }
        }
        // grabber(손잡이) 자리 확보 — 없으면 시트 맨 위 손잡이/둥근모서리에 상단이 가려진다.
        .padding(.top, options.showGrabber ? theme.space.lg                 // 24 — 손잡이 아래로
                                           : theme.space.cardPadding)       // 20 — 손잡이 없을 때
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
