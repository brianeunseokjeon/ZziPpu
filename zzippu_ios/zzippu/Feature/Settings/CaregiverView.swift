// Feature/Settings/CaregiverView.swift
// 공동양육자 공유 (설정 → push).
//   초대코드 발급 → 코드/만료 표시 + ShareSheet 공유
//   멤버 목록 표시
//   코드 입력으로 합류(joinByCode)

import SwiftUI

struct CaregiverView: View {
    @Bindable var vm: CaregiverViewModel
    @Environment(\.theme) private var theme

    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                inviteSection
                DSListRowDivider()
                membersSection
                DSListRowDivider()
                joinSection
            }
            .padding(.vertical, theme.space.lg)
        }
        .background(theme.color.background.color)
        .navigationTitle("공동양육자")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            if let text = vm.shareText {
                ShareSheet(items: [text])
            }
        }
        .onAppear { if vm.members.isEmpty { vm.loadMembers() } }
    }

    // MARK: - Invite

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "초대코드")

            VStack(alignment: .leading, spacing: theme.space.md) {
                Text("배우자·조부모를 초대해 같은 아기 기록을 함께 관리하세요.")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)

                if let invite = vm.invite {
                    HStack {
                        Text(invite.code)
                            .font(theme.typography.mono)
                        Spacer()
                        DSStatusPill(tone: .info, text: "\(vm.expiryText(invite.expiresAt)) 만료")
                    }
                    .padding(theme.space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        theme.color.surface.color,
                        in: RoundedRectangle(cornerRadius: theme.radius.control)
                    )

                    DSButton("코드 공유", variant: .secondary) {
                        showShare = true
                    }
                } else {
                    DSButton("초대코드 발급", isLoading: vm.isCreatingInvite) {
                        vm.createInvite()
                    }
                }
            }
            .padding(.horizontal, theme.space.screenPaddingX)
        }
    }

    // MARK: - Members

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "함께하는 사람")

            if vm.isLoadingMembers {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.space.md)
            } else if vm.members.isEmpty {
                DSEmptyState(icon: "person.2", message: "아직 함께하는 사람이 없어요")
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.members) { member in
                        DSListRow(variant: .withTrailing) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(theme.color.primary.color)
                        } content: {
                            Text(member.roleLabel)
                                .font(theme.typography.bodyStrong)
                        } trailing: {
                            Text(member.joinedAt.relativeLabel)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.color.textTertiary.color)
                        }
                        DSListRowDivider()
                    }
                }
            }
        }
    }

    // MARK: - Join

    private var joinSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            DSSectionHeader(title: "코드로 합류")

            VStack(alignment: .leading, spacing: theme.space.md) {
                DSTextField(
                    label: "초대코드",
                    placeholder: "받은 코드 입력",
                    text: $vm.joinCode,
                    state: vm.joinError.map { .error($0) } ?? .normal
                )
                DSButton("합류하기", variant: .secondary, isLoading: vm.isJoining) {
                    vm.join()
                }
                .disabled(vm.joinCode.trimmingCharacters(in: .whitespaces).count < 4)
            }
            .padding(.horizontal, theme.space.screenPaddingX)
        }
    }
}

// MARK: - Preview

#Preview("CaregiverView — 라이트") {
    NavigationStack {
        CaregiverView(vm: CaregiverViewModel(
            caregiverRepository: AppContainer.preview.caregiverRepository,
            babyRepository: AppContainer.preview.babyRepository,
            babyId: UUID()
        ))
    }
    .environment(\.theme, .zzippu)
}

#Preview("CaregiverView — 다크") {
    NavigationStack {
        CaregiverView(vm: CaregiverViewModel(
            caregiverRepository: AppContainer.preview.caregiverRepository,
            babyRepository: AppContainer.preview.babyRepository,
            babyId: UUID()
        ))
    }
    .environment(\.theme, .zzippu)
    .preferredColorScheme(.dark)
}
