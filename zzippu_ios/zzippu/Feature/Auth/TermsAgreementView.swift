// Feature/Auth/TermsAgreementView.swift
// 약관 동의 화면 — 필수 항목 모두 동의 시 완료 버튼 활성화

import SwiftUI

struct TermsAgreementView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme
    @State private var vm: TermsViewModel?

    var body: some View {
        Group {
            if let vm {
                TermsContent(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.color.background.color)
            }
        }
        .task {
            if vm == nil {
                let newVM = TermsViewModel(authRepository: container.authRepository)
                let capturedContainer = container
                newVM.onTermsAgreed = {
                    capturedContainer.sessionState.markTermsAgreed()
                }
                vm = newVM
                await vm?.loadTerms()
            }
        }
    }
}

// MARK: - Content

private struct TermsContent: View {
    @Bindable var vm: TermsViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 전체 동의 토글
                HStack {
                    Button(action: vm.toggleAll) {
                        Label(
                            "전체 동의",
                            systemImage: vm.allAgreed ? "checkmark.circle.fill" : "circle"
                        )
                        .font(theme.typography.body.weight(.semibold))
                        .foregroundStyle(vm.allAgreed ? theme.color.primary.color : theme.color.textSecondary.color)
                    }
                    Spacer()
                }
                .padding(theme.space.md)
                .background(
                    theme.color.surface.color,
                    in: RoundedRectangle(cornerRadius: theme.radius.control)
                )
                .padding([.horizontal, .top], theme.space.md)

                // 개별 약관 목록
                if vm.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                    Spacer()
                } else {
                    List(vm.terms) { term in
                        TermRow(
                            term: term,
                            isAgreed: vm.agreed[term.id] == true,
                            onToggle: { vm.toggle(term: term) },
                            onDetail: { vm.selectedTerm = term }
                        )
                    }
                    .listStyle(.insetGrouped)
                }

                // 동의 완료 버튼
                DSButton(
                    "동의하고 시작하기",
                    isLoading: vm.isSubmitting
                ) {
                    Task { await vm.agreeAndContinue() }
                }
                .disabled(!vm.canProceed)
                .padding(theme.space.md)
            }
            .background(theme.color.background.color)
            .navigationTitle("서비스 이용약관")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("오류", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .sheet(item: $vm.selectedTerm) { term in
            TermDetailSheet(term: term)
        }
    }
}

// MARK: - Term Row

private struct TermRow: View {
    let term: TermDoc
    let isAgreed: Bool
    let onToggle: () -> Void
    let onDetail: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isAgreed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isAgreed ? theme.color.primary.color : theme.color.textSecondary.color)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if term.required {
                        Text("[필수]")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.primary.color)
                            .fontWeight(.semibold)
                    } else {
                        Text("[선택]")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }
                    Text(term.title)
                        .font(theme.typography.body)
                }
            }

            Spacer()

            Button(action: onDetail) {
                Image(systemName: "chevron.right")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Term Detail Sheet

private struct TermDetailSheet: View {
    let term: TermDoc
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(term.content)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textPrimary.color)
                    .padding(theme.space.md)
            }
            .navigationTitle(term.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

// MARK: - TermsViewModel

@Observable
final class TermsViewModel {
    var terms: [TermDoc] = []
    var agreed: [String: Bool] = [:]
    var isLoading: Bool = false
    var isSubmitting: Bool = false
    var errorMessage: String? = nil
    var selectedTerm: TermDoc? = nil

    var onTermsAgreed: (() -> Void)?

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    // MARK: - Actions

    func loadTerms() async {
        await MainActor.run { isLoading = true }
        do {
            let loaded = try await authRepository.fetchTerms()
            await MainActor.run {
                terms = loaded
                agreed = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, false) })
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    func toggle(term: TermDoc) {
        agreed[term.id] = !(agreed[term.id] ?? false)
    }

    func toggleAll() {
        let newState = !allAgreed
        for term in terms {
            agreed[term.id] = newState
        }
    }

    func agreeAndContinue() async {
        guard canProceed else { return }
        await MainActor.run { isSubmitting = true }
        do {
            let toAgree = terms
                .filter { agreed[$0.id] == true }
                .map { (type: $0.type, version: $0.version) }
            try await authRepository.agreeTerms(toAgree)
            await MainActor.run {
                isSubmitting = false
                onTermsAgreed?()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }

    // MARK: - Computed

    var allAgreed: Bool {
        guard !terms.isEmpty else { return false }
        return terms.allSatisfy { agreed[$0.id] == true }
    }

    /// 필수 항목 전부 동의해야 진행 가능
    var canProceed: Bool {
        terms.filter(\.required).allSatisfy { agreed[$0.id] == true }
    }
}
