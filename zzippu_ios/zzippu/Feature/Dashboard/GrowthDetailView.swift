// Feature/Dashboard/GrowthDetailView.swift
// 성장곡선 상세 화면 — LineMark + PointMark, 지표 DSChip 토글.
// 상단 "+ 기록" 버튼 → 성장 입력 바텀시트.
// WHO 백분위 밴드 자리 예약 (AreaMark 오버레이, 데이터 없어 이번엔 실측 라인만).

import SwiftUI
import Charts

struct GrowthDetailView: View {

    @State var vm: GrowthViewModel
    @Environment(\.theme) private var theme
    @Environment(ToastCenter.self) private var toastCenter

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 지표 토글 (DSChip 세그먼트)
                HStack(spacing: 8) {
                    ForEach(GrowthMetric.allCases) { metric in
                        DSChip(
                            label:      metric.rawValue,
                            isSelected: vm.selectedMetric == metric,
                            variant:    .selectable,
                            onTap:      { vm.selectedMetric = metric }
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                // 현재 값 요약
                CardContainer(style: .sunken) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("최근 \(vm.selectedMetric.rawValue)")
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.color.textSecondary.color)
                            Text(vm.latestValueText)
                                .font(theme.typography.display)
                                .dsDynamicTypeCap()
                                .foregroundStyle(theme.color.textPrimary.color)
                        }
                        Spacer()
                        if let last = vm.series.last {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("기록일")
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.color.textTertiary.color)
                                Text(last.recordedAt, format: .dateTime.month().day())
                                    .font(theme.typography.bodyStrong)
                                    .foregroundStyle(theme.color.textPrimary.color)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // 성장 차트
                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(vm.selectedMetric.rawValue) 추이 (\(vm.selectedMetric.unit))")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)

                        if vm.chartPoints.isEmpty {
                            DSEmptyState(
                                icon: "chart.line.uptrend.xyaxis",
                                message: "성장 기록이 없어요\n+ 기록 버튼으로 첫 기록을 남겨보세요"
                            )
                            .frame(height: 220)
                        } else {
                            let band = vm.whoBand
                            Chart {
                                // WHO 백분위 밴드 오버레이 (p3–p97 옅게, p15–p85 진하게, p50 파선).
                                // 아기 나이에서 보간한 값 → 실측 라인 뒤 가로 밴드로 표시.
                                // WHO 미제공 지표(키·머리둘레)·성별 미상 시 band=nil → 생략.
                                if let band {
                                    RectangleMark(
                                        yStart: .value("p3", band.p3),
                                        yEnd:   .value("p97", band.p97)
                                    )
                                    .foregroundStyle(theme.color.statusInfoSolid.color.opacity(0.08))

                                    RectangleMark(
                                        yStart: .value("p15", band.p15),
                                        yEnd:   .value("p85", band.p85)
                                    )
                                    .foregroundStyle(theme.color.statusInfoSolid.color.opacity(0.16))

                                    RuleMark(y: .value("p50 (중앙값)", band.p50))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                        .foregroundStyle(theme.color.textTertiary.color)
                                }

                                // 실측 라인
                                ForEach(vm.chartPoints) { point in
                                    LineMark(
                                        x: .value("날짜", point.date),
                                        y: .value(vm.selectedMetric.rawValue, point.value)
                                    )
                                    .foregroundStyle(theme.color.primary.color)
                                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                                    PointMark(
                                        x: .value("날짜", point.date),
                                        y: .value(vm.selectedMetric.rawValue, point.value)
                                    )
                                    .foregroundStyle(theme.color.primary.color)
                                    .symbolSize(40)
                                    .annotation(position: .top) {
                                        Text(String(format: "%.1f", point.value))
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.color.textSecondary.color)
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisGridLine().foregroundStyle(theme.color.divider.color)
                                    AxisValueLabel(format: .dateTime.month().day())
                                        .foregroundStyle(theme.color.textTertiary.color)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine().foregroundStyle(theme.color.divider.color)
                                    AxisValueLabel {
                                        if let v = value.as(Double.self) {
                                            Text(String(format: "%.1f", v))
                                                .font(theme.typography.caption)
                                                .foregroundStyle(theme.color.textTertiary.color)
                                        }
                                    }
                                }
                            }
                            .frame(height: 260)

                            // WHO 백분위 코멘트 + 면책 (밴드가 있을 때만)
                            if let comment = vm.whoPercentileComment {
                                Text(comment)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.color.textSecondary.color)
                                    .fixedSize(horizontal: false, vertical: true)
                                DSDisclaimerCaption("WHO 성장표(2006) 참고 · 진단이 아니에요")
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // 성장 기록 목록
                if !vm.series.isEmpty {
                    DSSectionHeader(title: "기록 목록")

                    ForEach(vm.series.reversed()) { record in
                        GrowthRecordRow(record: record, metric: vm.selectedMetric) {
                            vm.deleteRecord(record)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("성장곡선")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.showInputSheet = true
                } label: {
                    Label("기록 추가", systemImage: "plus")
                }
            }
        }
        .dsBottomSheet(
            isPresented: Binding(
                get: { vm.showInputSheet },
                set: { vm.showInputSheet = $0 }
            ),
            options: .init(title: "성장 기록", detents: [.medium, .large])
        ) {
            GrowthInputSheet(
                isPresented: Binding(
                    get: { vm.showInputSheet },
                    set: { vm.showInputSheet = $0 }
                ),
                babyId: vm.series.first?.babyId ?? UUID()
            ) { record in
                Task { @MainActor in
                    await vm.saveRecord(record)
                    toastCenter.show(.init(message: "성장 기록 완료!", variant: .success))
                }
            }
        }
        .onAppear { vm.loadSeries() }
    }
}

// MARK: - GrowthRecordRow

struct GrowthRecordRow: View {
    let record:   GrowthRecord
    let metric:   GrowthMetric
    let onDelete: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.recordedAt, format: .dateTime.year().month().day())
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)

                HStack(spacing: 12) {
                    if let w = record.weightG {
                        Text(String(format: "%.2fkg", Double(w) / 1000.0))
                            .font(theme.typography.body)
                            .foregroundStyle(theme.color.textPrimary.color)
                    }
                    if let h = record.heightCm {
                        Text(String(format: "%.1fcm", h))
                            .font(theme.typography.body)
                            .foregroundStyle(theme.color.textPrimary.color)
                    }
                    if let hc = record.headCircumferenceCm {
                        Text(String(format: "머리 %.1fcm", hc))
                            .font(theme.typography.body)
                            .foregroundStyle(theme.color.textPrimary.color)
                    }
                }
            }
            Spacer()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(theme.color.statusDangerFg.color)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(theme.color.surface.color)
        .clipShape(RoundedRectangle(cornerRadius: theme.component.card.radius * 0.75))
    }
}

// MARK: - GrowthInputSheet

struct GrowthInputSheet: View {

    @Binding var isPresented: Bool
    let babyId: UUID
    let onSaved: (GrowthRecord) -> Void

    @State private var weightKgStr: String = ""
    @State private var heightCmStr: String = ""
    @State private var headCmStr:   String = ""
    @State private var recordedAt:  Date   = .now

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 기록일
                DatePicker("기록 날짜", selection: $recordedAt, displayedComponents: .date)
                    .font(theme.typography.body)
                    .padding(.horizontal, 16)

                // 체중
                VStack(alignment: .leading, spacing: 6) {
                    Text("체중 (kg)")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DSTextField(
                        placeholder: "예: 4.2",
                        text: $weightKgStr,
                        keyboardType: .decimalPad
                    )
                }
                .padding(.horizontal, 16)

                // 키
                VStack(alignment: .leading, spacing: 6) {
                    Text("키 (cm)")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DSTextField(
                        placeholder: "예: 55.5",
                        text: $heightCmStr,
                        keyboardType: .decimalPad
                    )
                }
                .padding(.horizontal, 16)

                // 머리둘레
                VStack(alignment: .leading, spacing: 6) {
                    Text("머리둘레 (cm)")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DSTextField(
                        placeholder: "예: 36.0",
                        text: $headCmStr,
                        keyboardType: .decimalPad
                    )
                }
                .padding(.horizontal, 16)

                // 저장 버튼
                DSButton("저장", variant: .primary, size: .lg) {
                    save()
                }
                .padding(.horizontal, 16)
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.5)
            }
            .padding(.vertical, 16)
        }
    }

    private var isValid: Bool {
        !weightKgStr.isEmpty || !heightCmStr.isEmpty || !headCmStr.isEmpty
    }

    private func save() {
        let weightG: Int? = Double(weightKgStr).map { Int($0 * 1000) }
        let heightCm: Double? = Double(heightCmStr)
        let headCm: Double? = Double(headCmStr)

        let record = GrowthRecord.new(
            babyId: babyId,
            recordedAt: recordedAt,
            weightG: weightG,
            heightCm: heightCm,
            headCircumferenceCm: headCm
        )
        onSaved(record)
        isPresented = false
    }
}

// MARK: - Preview

#Preview("GrowthDetailView") {
    NavigationStack {
        GrowthDetailView(
            vm: GrowthViewModel(
                growthRepository: AppContainer.preview.growthRepository,
                babyId: AppContainer.preview.activeBabyId
            )
        )
    }
    .environment(AppContainer.preview)
    .environment(ToastCenter())
    .environment(\.theme, .zzippu)
}
