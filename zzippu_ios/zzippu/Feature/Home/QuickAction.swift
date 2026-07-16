// Feature/Home/QuickAction.swift
// 홈 퀵버튼 1개의 추상화 — 카탈로그(전체 정의) + kind↔HomeAction 매핑.
// 이 파일이 "하드코딩 데이터"의 단일 소스이다.

import Foundation

// MARK: - QuickAction

/// 홈 빠른기록 버튼 1개의 추상화.
/// • kind: 저장 안정 ID (QuickButtonKind rawValue)
/// • emoji/label: 표시 텍스트
/// • action: HomeView.handleAction 라우팅 대상
/// • isSessionToggle: 수면처럼 활성 세션 시 라벨/색이 바뀌는 버튼
struct QuickAction: Equatable {
    let kind:            QuickButtonKind
    let emoji:           String
    /// 기본 라벨. 수면은 세션 상태에 따라 호출부에서 토글.
    let label:           String
    let action:          HomeAction
    /// true = 활성 세션 중 라벨/색 토글 대상(수면만 해당)
    let isSessionToggle: Bool

    static func == (lhs: QuickAction, rhs: QuickAction) -> Bool {
        lhs.kind == rhs.kind
    }
}

// MARK: - 카탈로그 (단일 소스)

/// 앱이 아는 모든 버튼의 순서·이모지·라벨.
/// 기본값 순서 = 현재 8개 전체.
/// ⚠️ QuickButtonKind case명·rawValue는 저장 키이므로 변경 금지.
enum QuickActionCatalog {

    static let all: [QuickAction] = [
        QuickAction(kind: .formula,    emoji: "🍼", label: "분유",    action: .formula,    isSessionToggle: false),
        QuickAction(kind: .breast,     emoji: "🤱", label: "모유",    action: .breast,     isSessionToggle: false),
        QuickAction(kind: .pee,        emoji: "💧", label: "소변",    action: .pee,        isSessionToggle: false),
        QuickAction(kind: .poo,        emoji: "💩", label: "대변",    action: .poo,        isSessionToggle: false),
        QuickAction(kind: .sleep,      emoji: "😴", label: "수면 시작", action: .sleep,      isSessionToggle: true),
        QuickAction(kind: .play,       emoji: "🎈", label: "터미타임", action: .play,       isSessionToggle: false),
        QuickAction(kind: .supplement, emoji: "🧴", label: "영양제",  action: .supplement, isSessionToggle: false),
        QuickAction(kind: .medicine,   emoji: "💊", label: "약",      action: .medicine,   isSessionToggle: false),
    ]

    /// kind → QuickAction 조회.
    static func action(for kind: QuickButtonKind) -> QuickAction? {
        all.first { $0.kind == kind }
    }

    /// 표시 kind 배열 + 활성 수면 세션 여부 → 렌더링할 [QuickAction] 계산.
    /// - hasActiveSleep: true이면 sleep을 표시 목록에 강제 포함(중복 없이, 목록 끝 보장).
    static func orderedActions(visibleKinds: [QuickButtonKind], hasActiveSleep: Bool) -> [QuickAction] {
        var kinds = visibleKinds
        // 활성 세션 중 수면 버튼 자동 노출 — 숨김 설정 무시, 저장값 불변.
        if hasActiveSleep && !kinds.contains(.sleep) {
            kinds.append(.sleep)
        }
        return kinds.compactMap { action(for: $0) }
    }
}
