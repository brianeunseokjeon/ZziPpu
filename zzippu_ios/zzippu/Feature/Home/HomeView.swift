// Feature/Home/HomeView.swift

import SwiftUI

struct HomeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme
    @State private var showFeedingSheet = false
    @State private var selectedDate: Date = .now

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // BigActionGrid (현재는 수유만)
                actionGrid

                Divider()

                // placeholder: 타임라인은 Feeding 슬라이스 이후 추가
                DSEmptyState(
                    icon: "clock",
                    message: "타임라인은 다음 슬라이스에서 추가됩니다"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("먹놀잠")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showFeedingSheet) {
            FeedingInputSheet(isPresented: $showFeedingSheet)
                .environment(container)
        }
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.space.md) {
            ActionButton(title: "수유", systemImage: "drop.fill", color: theme.color.domainFeedingFormulaSolid.color) {
                showFeedingSheet = true
            }
            ActionButton(title: "수면", systemImage: "moon.fill", color: .indigo) {
                // 다음 슬라이스
            }
            ActionButton(title: "기저귀", systemImage: "heart.fill", color: .green) {
                // 다음 슬라이스
            }
            ActionButton(title: "놀이", systemImage: "figure.play", color: .orange) {
                // 다음 슬라이스
            }
        }
        .padding(theme.space.md)
    }
}

// MARK: - ActionButton

private struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.space.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.color.textPrimary.color)
            }
            .frame(maxWidth: .infinity)
            .padding(theme.space.lg)
        }
        .buttonStyle(.plain)
        .dsCard(style: .interactive)
    }
}
