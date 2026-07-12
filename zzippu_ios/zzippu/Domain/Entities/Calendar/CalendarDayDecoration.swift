// Domain/Entities/Calendar/CalendarDayDecoration.swift
// 달력 날짜 칸에 얹히는 데코레이션 도메인 모델.
// Foundation only — 색/폰트 일절 없음(View 책임).

import Foundation

// MARK: - CalendarDecorationSlot

/// 셀 내 위치 슬롯. 슬롯이 분리돼 있어 미래 데코 추가 시 충돌을 명시적으로 드러냄.
enum CalendarDecorationSlot {
    case primaryValue   // 날짜 숫자 아래 큰 숫자 (수유량)
    case eventBadge     // 우상단 도트+라벨 (검진 시작일)
    case underbar       // 셀 최하단 얇은 가로 바 (검진 창 구간)
    case footnote       // 예약 슬롯(미래 확장용)
}

// MARK: - CalendarDecorationKind

/// 어떤 도메인인가 — 범례·View의 kind→theme 색 매핑 키.
/// 새 도메인 추가 시 case 1개 + Provider 구현 1개만 추가.
enum CalendarDecorationKind: String {
    case feedingVolume   // 수유량 숫자 텍스트
    case checkupWindow   // 영유아 검진 창
    // 미래: case sleepTotal / case vaccination ...
}

// MARK: - SpanRole

/// 구간 데코 전용 역할. start/end의 언더바를 캡슐 라운드로 처리하기 위함.
enum SpanRole {
    case single   // 단독 칸(start==end)
    case start    // 구간 첫 날
    case middle   // 구간 중간
    case end      // 구간 마지막 날
}

// MARK: - CalendarDayDecoration

/// 하나의 날짜 칸에 얹히는 데코레이션 하나.
/// 색/폰트는 담지 않음 — View가 kind → theme 토큰으로 매핑.
struct CalendarDayDecoration: Identifiable {
    let id: UUID
    let date: Date                      // KST 자정 기준 날짜
    let kind: CalendarDecorationKind
    let slot: CalendarDecorationSlot
    let text: String?                   // 예: "720", "2차"
    let spanRole: SpanRole?             // 구간 데코 전용(underbar에서 사용)

    init(
        id: UUID = UUID(),
        date: Date,
        kind: CalendarDecorationKind,
        slot: CalendarDecorationSlot,
        text: String? = nil,
        spanRole: SpanRole? = nil
    ) {
        self.id       = id
        self.date     = date
        self.kind     = kind
        self.slot     = slot
        self.text     = text
        self.spanRole = spanRole
    }
}
