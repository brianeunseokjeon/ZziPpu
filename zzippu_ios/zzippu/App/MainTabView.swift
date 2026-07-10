// App/MainTabView.swift
// T1/T3: DSTabBar 기반 4탭 셸.
//   0 홈     house.fill          → HomeView (기능)
//   1 대시보드 heart.text.square.fill → DashboardView (T3)
//   2 발달    figure.child        → DSEmptyState placeholder
//   3 설정    gearshape.fill      → DSEmptyState placeholder
// selectedDate는 탭 전환해도 유지 (홈·대시보드 공유 예정).

import SwiftUI

struct MainTabView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.theme)          private var theme

    @State private var selection: Int = 0

    private let tabItems = [
        DSTabItem(id: 0, systemName: "house.fill",              label: "홈"),
        DSTabItem(id: 1, systemName: "heart.text.square.fill",  label: "대시보드"),
        DSTabItem(id: 2, systemName: "figure.child",            label: "발달"),
        DSTabItem(id: 3, systemName: "gearshape.fill",          label: "설정"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tab content
            ZStack {
                // 홈 — 항상 로드 유지 (숨김 처리로 상태 보존)
                HomeView()
                    .environment(container)
                    .opacity(selection == 0 ? 1 : 0)
                    .allowsHitTesting(selection == 0)

                if selection == 1 {
                    DashboardView()
                        .environment(container)
                } else if selection == 2 {
                    placeholderView("발달", systemImage: "figure.child")
                } else if selection == 3 {
                    placeholderView("설정", systemImage: "gearshape.fill")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            DSTabBar(items: tabItems, selection: $selection)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func placeholderView(_ title: String, systemImage: String) -> some View {
        VStack(spacing: theme.space.stackGapMd) {
            DSEmptyState(
                icon: systemImage,
                message: "\(title)\n다음 슬라이스에서 구현됩니다"
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.color.background.color)
    }
}

// MARK: - Preview

#Preview("MainTabView") {
    MainTabView()
        .environment(AppContainer())
        .environment(\.theme, .zzippu)
        .environment(ToastCenter())
}
