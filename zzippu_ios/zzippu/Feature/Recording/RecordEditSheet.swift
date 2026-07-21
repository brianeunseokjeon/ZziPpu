// Feature/Recording/RecordEditSheet.swift
// RecordEditSheet — 기록 수정 시트 (웹 features/recording/RecordEditSheet.tsx 재현).
//   • feeding(분유: 양 ml 프리셋+수정 / 모유: 좌·우·양) + 시작시각(+종료시각)
//   • diaper(소변/대변/둘다) + 시각
//   • sleep(시작·종료 시각)
//   • play(터미타임/자유놀이/감각놀이) + 시각(+종료)
//   • 하단 삭제 버튼(휴지통, danger). 저장 시 즉시 닫고 백그라운드 반영(낙관적).
// 리포지토리는 HomeViewModel(Domain 프로토콜만 의존)을 통해 호출 → Feature→Domain 경계 유지.

import SwiftUI

// MARK: - RecordEditSheet

/// 편집 대상 도메인 원본을 받아 타입별 편집 UI를 렌더.
/// 저장/삭제는 `vm`의 편집 메서드로 위임(낙관적 반영). 완료 시 `onClose()`.
struct RecordEditSheet: View {
    let record: EditableRecord
    @Bindable var vm: HomeViewModel
    let onClose: () -> Void
    /// 토스트 발행(선택). 배변 빠른 추가 안내 등.
    var onToast: ((String) -> Void)? = nil

    @Environment(\.theme) private var theme

    // ─── 타입별 로컬 상태 ───
    @State private var formulaMl: Int = 100
    @State private var didVomit: Bool = false
    @State private var breastSide: BreastSide = .both
    @State private var diaperType: DiaperType = .pee
    @State private var diaperAmount: DiaperAmount? = nil
    @State private var stoolTexture: StoolState? = nil
    @State private var stoolColor: StoolColor? = nil
    @State private var playType: PlayType = .tummyTime

    @State private var startTime: Date = .now
    @State private var endTime: Date = .now
    @State private var hasEnd: Bool = false

    @State private var memoText: String = ""

    @State private var showDeleteConfirm = false

    private enum BreastSide { case left, right, both }

    // 20ml 배수로 쭉 (20 … 300).
    private static let mlPresets = Array(stride(from: 20, through: 300, by: 20))

    var body: some View {
        // ⚠️ DSBottomSheet가 콘텐츠를 이미 ScrollView로 감싸고 하단 여백·네이티브 시트
        // 세이프에어리어를 처리한다. 여기서 GeometryReader/ScrollView를 또 쓰면 높이가
        // 붕괴돼 내용이 사라진다(버튼만 남음). 그래서 단순 VStack만 둔다.
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: theme.space.md) {
                typeFields
                timeFields
                memoField
            }

            // ── 저장/삭제 ──
            HStack(spacing: theme.space.sm) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.color.statusDangerFg.color)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: theme.component.button.radius, style: .continuous)
                                .fill(theme.color.statusDangerBg.color)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("삭제")

                DSButton("저장", variant: .primary, size: .lg) {
                    handleSave()
                    onClose()
                }
            }
            .padding(.top, theme.space.md)
        }
        .background(theme.color.surface.color)
        .onAppear(perform: seedState)
        .confirmationDialog(
            "이 기록을 삭제할까요?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                handleDelete()
                onClose()
            }
            Button("취소", role: .cancel) {}
        }
    }

    // MARK: - 타입별 필드

    @ViewBuilder
    private var typeFields: some View {
        switch record {
        case .feeding(let f) where f.type == .formula:
            formulaFields
        case .feeding:
            breastFields
        case .diaper:
            diaperFields
        case .play:
            playFields
        case .sleep:
            EmptyView()
        }
    }

    // ── 분유 ──
    private var formulaFields: some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Spacer()
                Text("\(formulaMl)")
                    .font(theme.typography.display)
                    .foregroundStyle(theme.color.domainFeedingFormulaSolid.color)
                Text("ml")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
                Spacer()
            }
            DSNumberStepper(value: $formulaMl, range: 10...500, step: 10, unit: "ml")

            // 프리셋 칩 — 현재 값에 해당(가장 가까운) 칩으로 자동 스크롤/센터.
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.space.sm) {
                        ForEach(Self.mlPresets, id: \.self) { ml in
                            DSChip(
                                label: "\(ml)ml",
                                isSelected: formulaMl == ml,
                                variant: .quick,
                                tint: theme.color.domainFeedingFormulaTint,
                                onTap: { formulaMl = ml }
                            )
                            .id(ml)
                        }
                    }
                    .padding(.horizontal, 1)
                }
                // 진입 시 + 값 변경 시 현재 값(가장 가까운 프리셋)으로 센터 스크롤.
                .onAppear { scrollToCurrent(proxy, animated: false) }
                .onChange(of: formulaMl) { scrollToCurrent(proxy, animated: true) }
            }

            // 먹고 토함 토글 — 켜면 타임라인에 🤮, 실제 섭취량이 준 양보다 적을 수 있음.
            Toggle(isOn: $didVomit) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("먹고 토함 🤮")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.color.textPrimary.color)
                    Text("실제 섭취량이 적을 수 있어요")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                }
            }
            .tint(theme.color.primary.color)
            .padding(.horizontal, theme.space.md)
            .padding(.vertical, theme.space.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                    .fill(theme.color.surfaceSunken.color)
            )
        }
    }

    /// formulaMl에 가장 가까운 프리셋 칩으로 스크롤(정확히 일치하면 그 칩).
    private func scrollToCurrent(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let nearest = Self.mlPresets.min(by: {
            abs($0 - formulaMl) < abs($1 - formulaMl)
        }) else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(nearest, anchor: .center) }
        } else {
            proxy.scrollTo(nearest, anchor: .center)
        }
    }

    // ── 모유 ──
    private var breastFields: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("어느 쪽으로 수유했나요?")
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textSecondary.color)
            HStack(spacing: theme.space.sm) {
                sideChip(.left,  "왼쪽")
                sideChip(.right, "오른쪽")
                sideChip(.both,  "양쪽")
            }
        }
    }

    private func sideChip(_ side: BreastSide, _ label: String) -> some View {
        DSChip(
            label: label,
            isSelected: breastSide == side,
            variant: .selectable,
            tint: theme.color.domainFeedingBreastBothTint,
            onTap: { breastSide = side }
        )
        .frame(maxWidth: .infinity)
    }

    // ── 배변 ── (종류는 기록 생성 시 확정 — 편집에선 변경 불가)
    private var diaperFields: some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            // 양 (소변·대변 공통) — 3칩 균등폭
            VStack(alignment: .leading, spacing: theme.space.xs) {
                Text("양")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
                DSSegmentedChips(
                    options:   DiaperAmount.allCases,
                    selection: $diaperAmount,
                    label:     { $0.displayName }
                )
            }

            // 질감 (대변/둘다일 때만, 3칩 묽음/보통/찰흙)
            if diaperType.hasPoo {
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("질감")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DSSegmentedChips(
                        options:   StoolState.diaperTextureCases,
                        selection: $stoolTexture,
                        label:     { $0.textureShortLabel }
                    )
                }

                // 대변 색 (5칩 compact 균등폭 — 가로스크롤 제거)
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("대변 색")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DSSegmentedChips(
                        options:   StoolColor.diaperColorCases,
                        selection: $stoolColor,
                        label:     { $0.diaperColorLabel },
                        tint:      { c in theme.color.swatch(for: c.stoolSwatch) },
                        compact:   true
                    )
                }
            }
        }
    }

    // ── 놀이 ──
    private var playFields: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("놀이 종류")
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textSecondary.color)
            HStack(spacing: theme.space.sm) {
                ForEach(PlayType.allCases, id: \.self) { t in
                    DSChip(
                        label: t.displayName,
                        isSelected: playType == t,
                        variant: .selectable,
                        tint: theme.color.domainPlayTint,
                        onTap: { playType = t }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - 시각 입력

    private var timeFields: some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            VStack(alignment: .leading, spacing: theme.space.xs) {
                Text(isDiaper ? "기록 시간" : "시작 시간")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)
                DatePicker("", selection: $startTime, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
            }

            if showsEnd {
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Toggle(isOn: $hasEnd) {
                        Text("종료 시간")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }
                    .tint(theme.color.primary.color)
                    if hasEnd {
                        DatePicker("", selection: $endTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                    }
                }
            }
        }
    }

    // MARK: - 메모 입력 필드 (모든 타입 공통)

    private var memoField: some View {
        DSTextField(
            label:       "메모",
            placeholder: "메모 (선택)",
            text:        $memoText
        )
    }

    // MARK: - 판별 헬퍼

    private var isDiaper: Bool { if case .diaper = record { return true }; return false }

    /// 종료 시간 노출: 모유/수면/놀이 (분유·배변 제외)
    private var showsEnd: Bool {
        switch record {
        case .feeding(let f): return f.type != .formula
        case .sleep, .play:   return true
        case .diaper:         return false
        }
    }

    private func diaperLabel(_ t: DiaperType) -> String {
        switch t {
        case .pee:  return "💧 소변"
        case .poo:  return "💩 대변"
        case .both: return "💧💩 둘다"
        }
    }

    private func diaperKind(_ t: DiaperType) -> DomainKind {
        switch t {
        case .pee:  return .diaperPee
        case .poo:  return .diaperPoop
        case .both: return .diaperBoth
        }
    }

    // MARK: - 초기 상태 주입

    private func seedState() {
        switch record {
        case .feeding(let f):
            if let ml = f.amountMl { formulaMl = ml }
            switch f.type {
            case .breastLeft:  breastSide = .left
            case .breastRight: breastSide = .right
            default:           breastSide = .both
            }
            startTime = f.startedAt
            if let e = f.endedAt { endTime = e; hasEnd = true }
            memoText = f.memo ?? ""
            didVomit = f.didVomit
        case .sleep(let s):
            startTime = s.startedAt
            if let e = s.endedAt { endTime = e; hasEnd = true }
            memoText = s.memo ?? ""
        case .diaper(let d):
            diaperType = d.diaperType
            diaperAmount = d.amount
            stoolTexture = d.stoolState
            stoolColor = d.stoolColor
            startTime = d.recordedAt
            memoText = d.memo ?? ""
        case .play(let p):
            playType = p.playType
            startTime = p.startedAt
            if let e = p.endedAt { endTime = e; hasEnd = true }
            memoText = p.memo ?? ""
        }
    }

    // MARK: - 저장

    private func handleSave() {
        // 지정한 시각(HH:mm)을 원본 일자에 적용.
        let start = combined(base: recordBaseDate, time: startTime)
        let end: Date? = (showsEnd && hasEnd) ? combined(base: recordBaseDate, time: endTime) : nil

        // 편집된 메모 정규화: 공백·개행 trim 후 빈 문자열이면 nil.
        let trimmed = memoText.trimmingCharacters(in: .whitespacesAndNewlines)
        let memoOut: String? = trimmed.isEmpty ? nil : trimmed

        switch record {
        case .feeding(let f):
            let updated: Feeding = {
                var u = f
                u.startedAt = start
                u.memo = memoOut       // 편집된 memo 반영
                if f.type == .formula {
                    u.type = .formula
                    u.amountMl = formulaMl
                    u.didVomit = didVomit    // 분유만 토함 토글 반영
                    u.endedAt = nil
                } else {
                    u.type = breastFeedingType
                    u.endedAt = end
                    if let e = end { u.durationMinutes = max(0, Int(e.timeIntervalSince(start) / 60)) }
                }
                return u
            }()
            Task { @MainActor in await vm.updateFeeding(updated) }

        case .diaper(let d):
            // 대변만 색·질감 유지(소변이면 nil 가드). 색·메모는 편집값 사용.
            let color = diaperType.hasPoo ? stoolColor : nil
            let texture = diaperType.hasPoo ? stoolTexture : nil
            let new = DiaperRecord.new(
                babyId: d.babyId, diaperType: diaperType, recordedAt: start,
                stoolColor: color, stoolState: texture, amount: diaperAmount, memo: memoOut
            )
            Task { @MainActor in await vm.replaceDiaper(oldId: d.id, with: new) }

        case .sleep(let s):
            // replaceSleep에 memo 전달 — T5 수면 memo 소실 버그 수정.
            Task { @MainActor in await vm.replaceSleep(oldId: s.id, startedAt: start, endedAt: end, memo: memoOut) }

        case .play(let p):
            let duration = end.map { max(1, Int($0.timeIntervalSince(start) / 60)) } ?? 0
            let new = PlayRecord.new(
                babyId: p.babyId, playType: playType, startedAt: start,
                endedAt: end, durationMinutes: duration, memo: memoOut
            )
            Task { @MainActor in await vm.replacePlay(oldId: p.id, with: new) }
        }
    }

    private var breastFeedingType: FeedingType {
        switch breastSide {
        case .left:  return .breastLeft
        case .right: return .breastRight
        case .both:  return .breastBoth
        }
    }

    /// 원본 기록의 날짜(연/월/일) — 시각만 바꾸고 날짜는 유지.
    private var recordBaseDate: Date {
        switch record {
        case .feeding(let f): return f.startedAt
        case .sleep(let s):   return s.startedAt
        case .diaper(let d):  return d.recordedAt
        case .play(let p):    return p.startedAt
        }
    }

    /// base 날짜 + time 의 시/분 을 합성.
    private func combined(base: Date, time: Date) -> Date {
        let cal = Calendar.kst
        let t = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(bySettingHour: t.hour ?? 0, minute: t.minute ?? 0, second: 0, of: base) ?? base
    }

    // MARK: - 삭제

    private func handleDelete() {
        let item = TimelineItem(from: record)
        Task { @MainActor in
            vm.delete(item, on: recordBaseDate)
        }
    }
}

// MARK: - TimelineItem(from EditableRecord)

private extension TimelineItem {
    init(from record: EditableRecord) {
        switch record {
        case .feeding(let f): self.init(from: f)
        case .sleep(let s):   self.init(from: s)
        case .diaper(let d):  self.init(from: d)
        case .play(let p):    self.init(from: p)
        }
    }
}

// MARK: - Preview

#Preview("RecordEditSheet — 분유(라이트)") {
    RecordEditSheetPreviewHost(kind: .formula)
        .environment(\.theme, .zzippu)
}

#Preview("RecordEditSheet — 수면(다크)") {
    RecordEditSheetPreviewHost(kind: .sleep)
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}

private struct RecordEditSheetPreviewHost: View {
    enum Kind { case formula, breast, diaper, sleep, play }
    let kind: Kind

    @Environment(\.theme) private var theme

    var body: some View {
        let babyId = UUID()
        let vm = HomeViewModel(
            feedingRepository: PreviewFeedingRepo(),
            babyRepository:    PreviewBabyRepo(),
            sleepRepository:   PreviewSleepRepo(),
            diaperRepository:  PreviewDiaperRepo(),
            playRepository:    PreviewPlayRepo(),
            careLogRepository: PreviewCareLogRepo(),
            babyId: babyId
        )
        let record: EditableRecord = {
            switch kind {
            case .formula: return .feeding(Feeding.new(babyId: babyId, type: .formula, amountMl: 120))
            case .breast:  return .feeding(Feeding.new(babyId: babyId, type: .breastBoth, durationMinutes: 15))
            case .diaper:  return .diaper(DiaperRecord.new(babyId: babyId, diaperType: .both))
            case .sleep:   return .sleep(SleepRecord.new(babyId: babyId))
            case .play:    return .play(PlayRecord.new(babyId: babyId, playType: .tummyTime))
            }
        }()
        return RecordEditSheet(record: record, vm: vm, onClose: {})
            .frame(height: 520)
            .background(theme.color.surface.color)
    }
}

// 프리뷰 전용 스텁 (no-op)
private struct PreviewFeedingRepo: FeedingRepository {
    func create(_ feeding: Feeding) async throws -> Feeding { feeding }
    func update(_ feeding: Feeding) async throws -> Feeding { feeding }
    func delete(id: UUID, babyId: UUID) async throws {}
    func fetch(id: UUID, babyId: UUID) async throws -> Feeding? { nil }
    func list(babyId: UUID, on day: Date) async throws -> [Feeding] { [] }
    func lastFeeding(babyId: UUID) async throws -> Feeding? { nil }
    func dailyTotals(babyId: UUID, from start: Date, to end: Date) async throws -> [DateVolume] { [] }
}
private struct PreviewBabyRepo: BabyRepository {
    func create(_ baby: Baby) async throws -> Baby { baby }
    func update(_ baby: Baby) async throws -> Baby { baby }
    func fetch(id: UUID) async throws -> Baby? { nil }
    func fetchAll() async throws -> [Baby] { [] }
    func activeBaby() async throws -> Baby? { nil }
    func joinByCode(_ code: String) async throws -> Baby { throw NSError(domain: "preview", code: 0) }
}
private struct PreviewSleepRepo: SleepRepository {
    func create(_ sleep: SleepRecord) async throws -> SleepRecord { sleep }
    func endSleep(id: UUID, babyId: UUID, endedAt: Date) async throws -> SleepRecord {
        SleepRecord.new(babyId: babyId)
    }
    func delete(id: UUID, babyId: UUID) async throws {}
    func list(babyId: UUID, on day: Date) async throws -> [SleepRecord] { [] }
    func activeSession(babyId: UUID) async throws -> SleepRecord? { nil }
}
private struct PreviewDiaperRepo: DiaperRepository {
    func create(_ diaper: DiaperRecord) async throws -> DiaperRecord { diaper }
    func delete(id: UUID, babyId: UUID) async throws {}
    func list(babyId: UUID, on day: Date) async throws -> [DiaperRecord] { [] }
}
private struct PreviewPlayRepo: PlayRepository {
    func create(_ play: PlayRecord) async throws -> PlayRecord { play }
    func delete(id: UUID, babyId: UUID) async throws {}
    func list(babyId: UUID, on day: Date) async throws -> [PlayRecord] { [] }
}

private struct PreviewCareLogRepo: CareLogRepository {
    func create(_ log: CareLog) async throws -> CareLog { log }
    func update(_ log: CareLog) async throws -> CareLog { log }
    func delete(id: UUID, babyId: UUID) async throws {}
    func list(babyId: UUID, on day: Date) async throws -> [CareLog] { [] }
}
