// Feature/Settings/SettingsView.swift
// 설정 탭 (4탭 마지막) — 건강앱/iOS 설정 감성 목록.
//   상단: BabyAvatar + 이름/나이 → 프로필 편집(push)
//   섹션: 아기 프로필 · 공동양육자 · 데이터 내보내기 · 계정(로그아웃/이메일/버전)

import SwiftUI

struct SettingsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme

    @State private var vm: SettingsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    SettingsContent(vm: vm)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(theme.color.background.color)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if vm == nil {
                let newVM = SettingsViewModel(
                    babyRepository: container.babyRepository,
                    authRepository: container.authRepository,
                    growthRepository: container.growthRepository,
                    babyId: container.activeBabyId
                )
                let captured = container
                newVM.onSignedOut = {
                    captured.sessionState.setSession(nil)
                    captured.sessionState.activeBabyRegistered = false
                }
                vm = newVM
                newVM.load()
            }
        }
    }
}

// MARK: - Content

private struct SettingsContent: View {
    @Bindable var vm: SettingsViewModel
    @Environment(AppContainer.self) private var container
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.theme) private var theme

    @State private var showLogoutConfirm = false
    @State private var exportShareItems: [Any]?
    @State private var showWeightSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: theme.space.lg) {
                profileHeader
                babyProfileSection
                weightSection
                caregiverSection
                exportSection
                accountSection
                #if DEBUG
                debugOfflineSection
                #endif
            }
            .padding(.vertical, theme.space.lg)
        }
        .sheet(isPresented: Binding(
            get: { exportShareItems != nil },
            set: { if !$0 { exportShareItems = nil } }
        )) {
            if let items = exportShareItems {
                ShareSheet(items: items)
            }
        }
        .confirmationDialog("로그아웃 하시겠어요?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) { vm.signOut() }
            Button("취소", role: .cancel) {}
        }
        .dsBottomSheet(
            isPresented: $showWeightSheet,
            options: .init(title: "성장 (키·몸무게)", detents: [.medium])
        ) {
            weightSheetContent
        }
    }

    // MARK: - Growth (키·몸무게)

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "성장 (키·몸무게)")
            VStack(spacing: 0) {
                Button {
                    vm.currentWeightKgText = ""   // 매번 새로 입력(프리필 없이 명확하게)
                    vm.currentHeightCmText = ""
                    showWeightSheet = true
                } label: {
                    DSListRow(variant: .withTrailing) {
                        Image(systemName: "figure.child")
                            .foregroundStyle(theme.color.primary.color)
                    } content: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("성장 (키·몸무게)").font(theme.typography.body)
                            Text(vm.latestGrowthSummary)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.color.textSecondary.color)
                        }
                    } trailing: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.color.textTertiary.color)
                    }
                }
                .buttonStyle(.plain)

                DSListRowDivider()

                NavigationLink {
                    growthManageDestination
                } label: {
                    DSListRow(variant: .navigable) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(theme.color.primary.color)
                    } content: {
                        Text("전체 기록 관리").font(theme.typography.body)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weightSheetContent: some View {
        VStack(alignment: .leading, spacing: theme.space.lg) {
            Text("오늘 잰 키·몸무게를 입력하면 성장 기록으로 저장돼요. (하나만 입력해도 돼요)")
                .font(theme.typography.callout)
                .foregroundStyle(theme.color.textSecondary.color)

            VStack(alignment: .leading, spacing: theme.space.xs) {
                HStack {
                    DSTextField(
                        placeholder: "예: 55.5",
                        text: $vm.currentHeightCmText,
                        keyboardType: .decimalPad
                    )
                    Text("cm")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.color.textSecondary.color)
                        .frame(width: 32)
                }
                if let note = vm.currentHeightValidation {
                    Text(note)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.statusDangerFg.color)
                }
            }

            VStack(alignment: .leading, spacing: theme.space.xs) {
                HStack {
                    DSTextField(
                        placeholder: "예: 3.50",
                        text: $vm.currentWeightKgText,
                        keyboardType: .decimalPad
                    )
                    Text("kg")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.color.textSecondary.color)
                        .frame(width: 32)
                }
                if let note = vm.currentWeightValidation {
                    Text(note)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.statusDangerFg.color)
                }
            }

            DSButton("저장", isLoading: vm.isSavingWeight) {
                Task {
                    let ok = await vm.saveGrowth()
                    if ok {
                        showWeightSheet = false
                        toastCenter.show(.init(message: "성장 기록을 저장했어요", variant: .success))
                    }
                }
            }
            .disabled(!vm.canSaveWeight)
        }
    }

    // MARK: - Growth Manage Destination (기존 GrowthDetailView 재사용)

    private var growthManageDestination: some View {
        GrowthDetailView(
            vm: GrowthViewModel(
                growthRepository: container.growthRepository,
                babyId: container.activeBabyId,
                babyRepository: container.babyRepository,
                guidelineRepository: container.guidelineRepository
            )
        )
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        NavigationLink {
            profileEditDestination
        } label: {
            HStack(spacing: theme.space.md) {
                BabyAvatar(photoURL: vm.photoURL, gender: vm.avatarGender, size: .lg)
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text(vm.baby?.name ?? "아기 정보")
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.color.textPrimary.color)
                    if let ageText = vm.ageText {
                        Text(ageText)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.color.textTertiary.color)
            }
            .padding(theme.space.md)
            .background(
                theme.color.surface.color,
                in: RoundedRectangle(cornerRadius: theme.radius.card)
            )
            .padding(.horizontal, theme.space.screenPaddingX)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sections

    private var babyProfileSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "아기")
            NavigationLink {
                profileEditDestination
            } label: {
                DSListRow(variant: .navigable) {
                    Image(systemName: "person.text.rectangle")
                        .foregroundStyle(theme.color.primary.color)
                } content: {
                    Text("프로필 편집").font(theme.typography.body)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var caregiverSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "공유")
            NavigationLink {
                caregiverDestination
            } label: {
                DSListRow(variant: .navigable) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(theme.color.primary.color)
                } content: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("공동양육자 초대").font(theme.typography.body)
                        Text("배우자·조부모와 기록 공유")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "데이터 내보내기")
            VStack(spacing: 0) {
                exportRow(label: "JSON으로 내보내기", format: "json", icon: "curlybraces")
                DSListRowDivider()
                exportRow(label: "CSV로 내보내기", format: "csv", icon: "tablecells")
            }
        }
    }

    private func exportRow(label: String, format: String, icon: String) -> some View {
        Button {
            if let url = vm.exportURL(format: format) {
                exportShareItems = [url]
            }
        } label: {
            DSListRow(variant: .navigable) {
                Image(systemName: icon)
                    .foregroundStyle(theme.color.primary.color)
            } content: {
                Text(label).font(theme.typography.body)
            }
        }
        .buttonStyle(.plain)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "계정")
            VStack(spacing: 0) {
                if let email = vm.loginEmail {
                    DSListRow(variant: .withTrailing) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(theme.color.textSecondary.color)
                    } content: {
                        Text("로그인 이메일").font(theme.typography.body)
                    } trailing: {
                        Text(email)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textTertiary.color)
                    }
                    DSListRowDivider()
                }

                DSListRow(variant: .withTrailing) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(theme.color.textSecondary.color)
                } content: {
                    Text("앱 버전").font(theme.typography.body)
                } trailing: {
                    Text(vm.appVersion)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                }
                DSListRowDivider()

                Button {
                    showLogoutConfirm = true
                } label: {
                    DSListRow(variant: .plain) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(theme.color.statusDangerFg.color)
                    } content: {
                        Text("로그아웃")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.color.statusDangerFg.color)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Debug (오프라인 킬 스위치 — DEBUG 빌드에서만 노출, 일반 사용자 숨김)

    #if DEBUG
    private var debugOfflineSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "개발자 (DEBUG)")
            VStack(spacing: 0) {
                Toggle(isOn: Binding(
                    get: { OfflineToggle.offlineEnabled },
                    set: { OfflineToggle.offlineEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("오프라인 저장 사용").font(theme.typography.body)
                        Text(debugOfflineHint)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }
                }
                .tint(theme.color.primary.color)
                .padding(theme.space.md)
                .background(
                    theme.color.surface.color,
                    in: RoundedRectangle(cornerRadius: theme.radius.card)
                )

                if OfflineToggle.isDisabledByFallback {
                    Button {
                        OfflineToggle.clearFallback()
                    } label: {
                        DSListRow(variant: .plain) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(theme.color.primary.color)
                        } content: {
                            Text("폴백 강등 해제 (재시작 후 재시도)")
                                .font(theme.typography.body)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, theme.space.screenPaddingX)
        }
    }

    private var debugOfflineHint: String {
        if OfflineToggle.isDisabledByFallback {
            return "초기화 실패로 강등됨 · 현재: \(container.isOfflineActive ? "오프라인" : "서버-전용") · 앱 재시작 시 반영"
        }
        return "현재: \(container.isOfflineActive ? "오프라인" : "서버-전용") · 앱 재시작 시 반영"
    }
    #endif

    // MARK: - Destinations (VM 생성 후 push)

    @ViewBuilder
    private var profileEditDestination: some View {
        if let baby = vm.baby {
            ProfileEditLoader(
                baby: baby,
                babyRepository: container.babyRepository,
                onSaved: { vm.applyUpdatedBaby($0) }
            )
        } else {
            DSEmptyState(icon: "person.crop.circle.badge.exclamationmark",
                         message: "프로필을 불러오는 중이에요")
        }
    }

    private var caregiverDestination: some View {
        CaregiverLoader(
            caregiverRepository: container.caregiverRepository,
            babyRepository: container.babyRepository,
            babyId: container.activeBabyId
        )
    }
}

// MARK: - Destination Loaders (VM 소유 — 재생성 방지 + 콜백 결선)

/// 프로필 편집 대상. @State로 VM을 한 번만 생성해 push 중 재생성/콜백 유실 방지.
private struct ProfileEditLoader: View {
    @State private var vm: BabyProfileViewModel

    init(baby: Baby, babyRepository: BabyRepository, onSaved: @escaping (Baby) -> Void) {
        let model = BabyProfileViewModel(baby: baby, babyRepository: babyRepository)
        model.onSaved = onSaved
        _vm = State(initialValue: model)
    }

    var body: some View { BabyProfileView(vm: vm) }
}

/// 공동양육 대상. @State로 VM을 한 번만 생성.
private struct CaregiverLoader: View {
    @State private var vm: CaregiverViewModel

    init(caregiverRepository: CaregiverRepository, babyRepository: BabyRepository, babyId: UUID) {
        _vm = State(initialValue: CaregiverViewModel(
            caregiverRepository: caregiverRepository,
            babyRepository: babyRepository,
            babyId: babyId
        ))
    }

    var body: some View { CaregiverView(vm: vm) }
}

// MARK: - Preview

#Preview("SettingsView — 라이트") {
    SettingsView()
        .environment(AppContainer.preview)
        .environment(ToastCenter())
        .environment(\.theme, .zzippu)
}

#Preview("SettingsView — 다크") {
    SettingsView()
        .environment(AppContainer.preview)
        .environment(ToastCenter())
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
