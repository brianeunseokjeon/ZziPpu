// Feature/Home/CareInputSheet.swift
// 영양제·약·목욕 기록 입력/편집 시트.
// - 영양제/약: 프리셋 종류 선택(+직접 추가) + 용량 + 시각 + 메모
// - 목욕: 시각 + 메모만 (생성은 원탭 즉시 — 이 시트는 편집에서만 목욕 표시)
// dsBottomSheet 안(이미 ScrollView)에서 쓰므로 내부에 ScrollView/List 중첩 금지.

import SwiftUI

struct CareInputSheet: View {

    @Binding var isPresented: Bool
    let babyId: UUID
    let category: CareCategory
    /// 편집 대상. nil이면 신규.
    let editing: CareLog?
    /// 신규 기록의 기본 시각(과거 날짜 입력 시 그 날짜). 편집이면 무시.
    let defaultDate: Date
    let onSaved: (CareLog) -> Void
    /// 편집 모드 삭제 콜백(신규면 nil).
    let onDelete: (() -> Void)?

    @Environment(\.theme) private var theme

    @State private var presets: [String]
    @State private var selectedName: String?
    @State private var doseText: String
    @State private var memoText: String
    @State private var recordedAt: Date
    @State private var addingPreset: Bool = false
    @State private var newPresetText: String = ""

    init(
        isPresented: Binding<Bool>,
        babyId: UUID,
        category: CareCategory,
        editing: CareLog? = nil,
        defaultDate: Date = .now,
        onSaved: @escaping (CareLog) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.babyId = babyId
        self.category = category
        self.editing = editing
        self.defaultDate = defaultDate
        self.onSaved = onSaved
        self.onDelete = onDelete
        _presets      = State(initialValue: CarePresetSettings.presets(for: category))
        _selectedName = State(initialValue: editing?.name)
        _doseText     = State(initialValue: editing?.dose ?? "")
        _memoText     = State(initialValue: editing?.memo ?? "")
        _recordedAt   = State(initialValue: editing?.recordedAt ?? defaultDate)
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.lg) {

            // ── 종류(프리셋) — 영양제/약만 ──
            if category != .bath {
                VStack(alignment: .leading, spacing: theme.space.sm) {
                    Text("종류")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)

                    // 종류 칩 — 라디우스 8·가로패딩 12·왼쪽정렬 자동 줄바꿈(DSSelectChip/FlowLayout 공용).
                    FlowLayout(spacing: theme.space.sm) {
                        ForEach(presets, id: \.self) { p in
                            DSSelectChip(label: p, isSelected: selectedName == p) {
                                selectedName = (selectedName == p ? nil : p)
                            }
                        }
                        DSSelectChip(label: "＋ 추가") { addingPreset = true }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if addingPreset {
                        HStack(spacing: theme.space.sm) {
                            DSTextField(placeholder: "새 종류 (예: 비타민D)", text: $newPresetText)
                            DSButton("추가", variant: .secondary, size: .sm) { addPreset() }
                        }
                    }

                    Text(selectedName == nil
                         ? "미선택 시 ‘\(category.displayName)’으로 기록돼요"
                         : "선택: \(selectedName ?? "")")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                }

                // ── 용량 ──
                DSTextField(label: "용량 (선택)", placeholder: "예: 5방울, 2.5ml", text: $doseText)
            }

            // ── 시각 ──
            DatePicker("기록 시각", selection: $recordedAt)
                .font(theme.typography.body)

            // ── 메모 ──
            DSTextField(label: "메모 (선택)", placeholder: "메모", text: $memoText)

            // ── 저장/삭제 ──
            DSButton(isEditing ? "수정" : "저장", variant: .primary, size: .lg) { save() }

            if isEditing, let onDelete {
                DSButton("삭제", variant: .destructive, size: .lg) {
                    onDelete()
                    isPresented = false
                }
            }
        }
        .padding(.horizontal, theme.space.screenPaddingX)
        .padding(.vertical, theme.space.md)
    }

    // MARK: - 조작

    private func addPreset() {
        let updated = CarePresetSettings.add(newPresetText, to: category)
        presets = updated
        let trimmed = newPresetText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { selectedName = trimmed }
        newPresetText = ""
        addingPreset = false
    }

    private func save() {
        let name = (category == .bath) ? nil : selectedName
        let dose = doseText.trimmingCharacters(in: .whitespacesAndNewlines)
        let memo = memoText.trimmingCharacters(in: .whitespacesAndNewlines)

        let log: CareLog
        if let editing {
            log = CareLog(
                id: editing.id,
                babyId: editing.babyId,
                category: editing.category,
                name: name,
                dose: dose.isEmpty ? nil : dose,
                recordedAt: recordedAt,
                memo: memo.isEmpty ? nil : memo,
                createdAt: editing.createdAt
            )
        } else {
            log = CareLog.new(
                babyId: babyId,
                category: category,
                name: name,
                dose: dose.isEmpty ? nil : dose,
                recordedAt: recordedAt,
                memo: memo.isEmpty ? nil : memo
            )
        }
        onSaved(log)
        isPresented = false
    }
}
