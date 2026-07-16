// Feature/Home/QuickBarEditSheet.swift
// 홈 빠른기록 바 커스터마이즈 편집 시트.
// DSBottomSheet(.large) + List + EditMode — 표시/숨김 2섹션, 드래그 재정렬, ⊟/⊕ 버튼.

import SwiftUI

// MARK: - QuickBarEditSheet

struct QuickBarEditSheet: View {
    /// 시트 닫기 콜백
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme
    @Environment(ToastCenter.self) private var toastCenter

    // MARK: - 편집 로컬 상태 (시트 내 in-memory, dismiss 시 UserDefaults 커밋)
    @State private var visibleKinds:  [QuickButtonKind] = []
    @State private var hiddenKinds:   [QuickButtonKind] = []
    @State private var showResetConfirm: Bool = false

    // MARK: - 계산 프로퍼티

    private var allCatalogKinds: [QuickButtonKind] { QuickActionCatalog.all.map(\.kind) }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ── 헤더 ──
            HStack {
                Text("빠른기록 편집")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.color.textPrimary.color)
                Spacer(minLength: 0)
                Button("완료") {
                    commit()
                    onDismiss()
                }
                .font(theme.typography.headline)
                .foregroundStyle(theme.color.primary.color)
            }
            .padding(.horizontal, theme.space.componentPaddingX)
            .padding(.bottom, theme.space.stackGapMd)

            Divider().foregroundStyle(theme.color.divider.color)

            // ── 리스트 ──
            List {
                // 표시 중 섹션
                Section {
                    ForEach(visibleKinds, id: \.self) { kind in
                        if let qa = QuickActionCatalog.action(for: kind) {
                            visibleRow(qa)
                        }
                    }
                    .onMove { indices, newOffset in
                        visibleKinds.move(fromOffsets: indices, toOffset: newOffset)
                        commit()   // 순서 변경 즉시 영속
                    }
                } header: {
                    Text("표시 중")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                        .textCase(nil)
                }

                // 숨김 섹션
                Section {
                    if hiddenKinds.isEmpty {
                        DSEmptyState(icon: "eye.slash", message: "숨긴 버튼이 없어요")
                            .padding(.vertical, theme.space.sm)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(hiddenKinds, id: \.self) { kind in
                            if let qa = QuickActionCatalog.action(for: kind) {
                                hiddenRow(qa)
                            }
                        }
                    }
                } header: {
                    Text("숨김")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                        .textCase(nil)
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))

            Divider().foregroundStyle(theme.color.divider.color)

            // ── 기본값 복원 버튼 ──
            DSButton("기본값으로 복원", variant: .tertiary, size: .sm) {
                showResetConfirm = true
            }
            .padding(.horizontal, theme.space.componentPaddingX)
            .padding(.vertical, theme.space.sm)
        }
        .background(theme.color.surface.color)
        .onAppear(perform: loadFromSettings)
        .confirmationDialog(
            "빠른기록 버튼을 기본으로 되돌릴까요?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("기본값으로 복원", role: .destructive) {
                resetToDefault()
            }
            Button("취소", role: .cancel) {}
        }
    }

    // MARK: - 표시 중 행

    @ViewBuilder
    private func visibleRow(_ qa: QuickAction) -> some View {
        let isLast = visibleKinds.count == 1

        HStack(spacing: 0) {
            // ⊟ 숨김 버튼
            Button {
                if isLast {
                    toastCenter.show(.init(message: "최소 1개는 남겨두세요", variant: .info))
                } else {
                    hide(qa.kind)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isLast ? theme.color.textTertiary.color : theme.color.statusDangerSolid.color)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .disabled(false) // 항상 활성(마지막이면 토스트)
            .accessibilityLabel("\(qa.label) 숨기기")

            // 이모지 + 색 도트 + 라벨
            HStack(spacing: theme.space.sm) {
                Text(qa.emoji).font(.system(size: 20))
                Text(qa.label)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.color.textPrimary.color)
                Spacer(minLength: 0)
            }
            .padding(.leading, theme.space.xs)
        }
        .frame(minHeight: 44)
        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 16))
        .listRowSeparator(.visible)
        .accessibilityElement(children: .combine)
        .accessibilityValue("표시 \(visibleKinds.count)개 중 \((visibleKinds.firstIndex(of: qa.kind) ?? 0) + 1)번째")
    }

    // MARK: - 숨김 행

    @ViewBuilder
    private func hiddenRow(_ qa: QuickAction) -> some View {
        HStack(spacing: 0) {
            // ⊕ 표시 추가 버튼
            Button {
                show(qa.kind)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.color.statusSuccessSolid.color)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .accessibilityLabel("\(qa.label) 추가")

            HStack(spacing: theme.space.sm) {
                Text(qa.emoji).font(.system(size: 20))
                Text(qa.label)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.color.textSecondary.color)
                Spacer(minLength: 0)
            }
            .padding(.leading, theme.space.xs)
        }
        .frame(minHeight: 44)
        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 16))
        .listRowSeparator(.visible)
    }

    // MARK: - 조작

    /// 표시 → 숨김 이동
    private func hide(_ kind: QuickButtonKind) {
        visibleKinds.removeAll { $0 == kind }
        if !hiddenKinds.contains(kind) {
            hiddenKinds.append(kind)
        }
        commit()   // 즉시 영속 — 완료 버튼 없이 스와이프로 닫아도 반영
    }

    /// 숨김 → 표시(맨 끝) 이동
    private func show(_ kind: QuickButtonKind) {
        hiddenKinds.removeAll { $0 == kind }
        if !visibleKinds.contains(kind) {
            visibleKinds.append(kind)
        }
        commit()
    }

    // MARK: - 기본값 복원

    private func resetToDefault() {
        let defaults = QuickBarSettings.defaultKinds
        visibleKinds = defaults
        hiddenKinds  = []
        commit()
    }

    // MARK: - 저장 (UserDefaults 커밋)

    private func commit() {
        // 최소 1개 방어 (이중 보장)
        if visibleKinds.isEmpty { visibleKinds = QuickBarSettings.defaultKinds }
        QuickBarSettings.visibleKinds = visibleKinds
    }

    // MARK: - 초기 로드

    private func loadFromSettings() {
        let visible = QuickBarSettings.visibleKinds
        visibleKinds = visible
        // 숨김 = 카탈로그 전체 − 표시
        hiddenKinds  = QuickActionCatalog.all.map(\.kind).filter { !visible.contains($0) }
    }
}

// MARK: - Preview

#Preview("QuickBarEditSheet — 라이트") {
    QuickBarEditSheet(onDismiss: {})
        .environment(\.theme, .zzippu)
        .environment(ToastCenter())
}

#Preview("QuickBarEditSheet — 다크") {
    QuickBarEditSheet(onDismiss: {})
        .environment(\.theme, .zzippu)
        .environment(ToastCenter())
        .preferredColorScheme(.dark)
}
