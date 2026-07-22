// Feature/Development/VaccinationContentView.swift
// 예방접종 목록 + 완료 처리 시트.

import SwiftUI

struct VaccinationContentView: View {

    @Bindable var vm: VaccinationViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if vm.sortedVaccinations.isEmpty && !vm.isLoading {
                    DSEmptyState(
                        icon: "syringe",
                        message: vm.errorMessage ?? "예정된 접종이 없어요"
                    )
                    .padding(.top, theme.space.xl)
                } else {
                    ForEach(vm.sortedVaccinations) { vaccination in
                        Button {
                            if !vaccination.isAdministered {
                                vm.beginEditing(vaccination)
                            }
                        } label: {
                            vaccinationRow(vaccination)
                        }
                        .buttonStyle(.plain)
                        .disabled(vaccination.isAdministered)
                        DSListRowDivider()
                    }
                }
            }
            .padding(.vertical, theme.space.sm)
        }
        .refreshable { vm.load() }
        .overlay {
            if vm.isLoading && vm.vaccinations.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .dsBottomSheet(
            isPresented: Binding(
                get: { vm.editingVaccination != nil },
                set: { if !$0 { vm.editingVaccination = nil } }
            ),
            options: .init(title: "접종 완료 처리", detents: [.medium])
        ) {
            if let target = vm.editingVaccination {
                VaccinationAdministerSheet(vm: vm, vaccination: target)
            }
        }
    }

    // MARK: - Row

    private func vaccinationRow(_ vaccination: Vaccination) -> some View {
        DSListRow(variant: .withTrailing) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rowTitle(vaccination))
                    .font(theme.typography.body)
                    .foregroundStyle(theme.color.textPrimary.color)
                Text(subtitle(vaccination))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
            }
        } trailing: {
            statusPill(vaccination)
        }
    }

    private func rowTitle(_ v: Vaccination) -> String {
        v.doseNumber > 0 ? "\(v.vaccineName) \(v.doseNumber)차" : v.vaccineName
    }

    private func subtitle(_ v: Vaccination) -> String {
        if let administered = v.administeredDate {
            let base = "\(Self.dateText(administered)) 접종"
            if let hospital = v.hospitalName, !hospital.isEmpty {
                return "\(base) · \(hospital)"
            }
            return base
        }
        return "권장일 \(Self.dateText(v.scheduledDate))"
    }

    @ViewBuilder
    private func statusPill(_ v: Vaccination) -> some View {
        if v.isAdministered {
            DSStatusPill(tone: .success, text: "완료")
        } else if v.isOverdue {
            DSStatusPill(tone: .danger, text: "지연")
        } else if v.isDueSoon {
            DSStatusPill(tone: .warning, text: dueSoonText(v))
        } else {
            DSStatusPill(tone: .info, text: dueText(v))
        }
    }

    private func dueSoonText(_ v: Vaccination) -> String {
        guard let days = v.daysUntil else { return "임박" }
        if days == 0 { return "오늘" }
        if days < 0 { return "\(-days)일 지남" }
        return "\(days)일 남음"
    }

    private func dueText(_ v: Vaccination) -> String {
        guard let days = v.daysUntil else { return "예정" }
        return "\(days)일 남음"
    }

    static func dateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.timeZone = .kst
        f.setLocalizedDateFormatFromTemplate("yMd")   // 기기 언어
        return f.string(from: date)
    }
}

// MARK: - 완료 처리 시트

private struct VaccinationAdministerSheet: View {

    @Bindable var vm: VaccinationViewModel
    let vaccination: Vaccination

    @Environment(\.theme) private var theme
    @State private var administeredDate: Date = .now
    @State private var hospitalName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.space.md) {
                    Text(title)
                        .font(theme.typography.bodyStrong)
                        .foregroundStyle(theme.color.textPrimary.color)

                    fieldLabel("접종일")
                    DatePicker(
                        "",
                        selection: $administeredDate,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()

                    fieldLabel("병원명 (선택)")
                    TextField("예: 우리아이소아과", text: $hospitalName)
                        .textFieldStyle(.roundedBorder)
                        .font(theme.typography.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.space.screenPaddingX)
                .padding(.vertical, theme.space.md)
            }

            DSButton("완료 처리", variant: .primary, size: .lg, isLoading: vm.isSubmitting) {
                vm.markAdministered(
                    id: vaccination.id,
                    administeredDate: administeredDate,
                    hospitalName: hospitalName
                )
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.bottom, theme.space.md)
        }
    }

    private var title: String {
        vaccination.doseNumber > 0
            ? "\(vaccination.vaccineName) \(vaccination.doseNumber)차"
            : vaccination.vaccineName
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(theme.typography.captionStrong)
            .foregroundStyle(theme.color.textSecondary.color)
    }
}
