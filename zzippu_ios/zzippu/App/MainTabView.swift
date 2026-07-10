// App/MainTabView.swift
// iOS 17 호환: TabView + .tabItem 방식

import SwiftUI

struct MainTabView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme

    var body: some View {
        TabView {
            HomeView()
                .environment(container)
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            placeholderView("대시보드", "다음 슬라이스에서 추가됩니다")
                .tabItem {
                    Label("대시보드", systemImage: "chart.bar.fill")
                }

            placeholderView("추세", "다음 슬라이스에서 추가됩니다")
                .tabItem {
                    Label("추세", systemImage: "chart.line.uptrend.xyaxis")
                }

            placeholderView("발달 정보", "번들 콘텐츠 슬라이스에서 추가됩니다")
                .tabItem {
                    Label("발달", systemImage: "sparkles")
                }

            placeholderView("더보기", "설정 및 기타 메뉴")
                .tabItem {
                    Label("더보기", systemImage: "ellipsis.circle")
                }
        }
    }

    private func placeholderView(_ title: String, _ subtitle: String) -> some View {
        DSEmptyState(icon: "clock", message: "\(title)\n\(subtitle)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.color.background.color)
    }
}
