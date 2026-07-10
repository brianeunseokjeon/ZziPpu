// Feature/Development/DevelopmentContentView.swift
// 발달 이정표 콘텐츠 — 현재 시기 카드 + 마일스톤 타임라인 (읽기 전용).

import SwiftUI

struct DevelopmentContentView: View {

    @Bindable var vm: DevelopmentViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: theme.space.sectionGap) {
                if let stage = vm.currentStage {
                    stageCard(stage)
                        .padding(.horizontal, theme.space.screenPaddingX)
                } else if !vm.isLoading {
                    DSEmptyState(
                        icon: "figure.child",
                        message: vm.errorMessage ?? "발달 정보가 아직 없어요"
                    )
                    .padding(.top, theme.space.xl)
                }

                if !vm.milestones.isEmpty {
                    DSSectionHeader(title: "발달 이정표")
                    milestoneTimeline
                        .padding(.horizontal, theme.space.screenPaddingX)
                }
            }
            .padding(.vertical, theme.space.screenPaddingY)
        }
        .refreshable { vm.load() }
        .overlay {
            if vm.isLoading && vm.currentStage == nil {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - 현재 시기 카드

    @ViewBuilder
    private func stageCard(_ stage: DevelopmentStage) -> some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            // 헤더: 라벨 + 나이 pill
            HStack(alignment: .firstTextBaseline) {
                Text(stage.label)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.color.textPrimary.color)
                Spacer()
                DSStatusPill(tone: .info, text: "생후 \(vm.ageDays)일")
            }

            Text(stage.summary)
                .font(theme.typography.body)
                .foregroundStyle(theme.color.textSecondary.color)

            // 6영역 섹션
            ForEach(DevelopmentArea.allCases, id: \.self) { area in
                let items = stage.items(for: area)
                if !items.isEmpty {
                    areaSection(title: area.label, items: items)
                }
            }

            // 부모 행동 가이드
            if !stage.parentActions.isEmpty {
                Divider().overlay(theme.color.divider.color)
                Text("이 시기 도움말")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)
                ForEach(stage.parentActions) { action in
                    parentActionRow(action)
                }
            }

            // 주의 신호
            if !stage.warningSigns.isEmpty {
                Divider().overlay(theme.color.divider.color)
                Label("전문가 상담이 필요한 신호", systemImage: "exclamationmark.triangle.fill")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.statusWarningFg.color)
                ForEach(Array(stage.warningSigns.enumerated()), id: \.offset) { _, sign in
                    bulletRow(sign, color: theme.color.statusWarningFg.color)
                }
            }

            // 출처
            if !stage.sources.isEmpty {
                Text("출처: " + stage.sources.joined(separator: ", "))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textTertiary.color)
                    .padding(.top, theme.space.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.space.md)
        .dsCard(style: .plain)
    }

    private func areaSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(title)
                .font(theme.typography.captionStrong)
                .foregroundStyle(theme.color.primary.color)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                bulletRow(item, color: theme.color.textPrimary.color)
            }
        }
    }

    private func bulletRow(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: theme.space.sm) {
            Text("•").foregroundStyle(theme.color.textTertiary.color)
            Text(text)
                .font(theme.typography.body)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func parentActionRow(_ action: ParentAction) -> some View {
        HStack(alignment: .top, spacing: theme.space.sm) {
            Text(action.icon)
                .font(theme.typography.body)
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(theme.typography.bodyStrong)
                    .foregroundStyle(theme.color.textPrimary.color)
                Text(action.detail)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 마일스톤 타임라인

    private var milestoneTimeline: some View {
        VStack(spacing: 0) {
            ForEach(vm.milestones) { milestone in
                milestoneRow(milestone)
            }
        }
        .dsCard(style: .sunken)
    }

    @ViewBuilder
    private func milestoneRow(_ milestone: Milestone) -> some View {
        let status = vm.status(for: milestone)
        HStack(spacing: theme.space.md) {
            Text(milestone.emoji)
                .font(.system(size: 22))
                .opacity(status == .upcoming ? 0.4 : 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.label)
                    .font(status == .current ? theme.typography.bodyStrong : theme.typography.body)
                    .foregroundStyle(labelColor(status))
                Text(milestone.description)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textTertiary.color)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            DSStatusPill(tone: categoryTone(milestone.category), text: statusText(status))
        }
        .padding(.horizontal, theme.space.componentPaddingX)
        .padding(.vertical, theme.space.sm)
        .background(
            status == .current ? theme.color.primaryTint.color : .clear
        )
    }

    // MARK: - 스타일 매핑

    private func labelColor(_ status: DevelopmentViewModel.MilestoneStatus) -> Color {
        switch status {
        case .past:     return theme.color.textSecondary.color
        case .current:  return theme.color.textPrimary.color
        case .upcoming: return theme.color.textTertiary.color
        }
    }

    private func statusText(_ status: DevelopmentViewModel.MilestoneStatus) -> String {
        switch status {
        case .past:     return "지남"
        case .current:  return "지금"
        case .upcoming: return "예정"
        }
    }

    private func categoryTone(_ category: Milestone.Category) -> StatusTone {
        switch category {
        case .celebration:   return .success
        case .checkup:       return .warning
        case .developmental: return .info
        }
    }
}
