// App/AppNavigationState.swift
// 앱 공용 내비게이션 상태 — 탭을 가로질러 이동(딥링크)하기 위한 작은 @Observable.
//   selectedTab: 현재 선택 탭(0 홈/1 대시보드/2 발달/3 설정) — 탭바 selection 바인딩.
//   developmentSegment: 발달 탭 진입 시 강제 전환할 세그먼트(소비 후 nil).
// 예) 대시보드 성장 카드 탭 → selectedTab=2 + developmentSegment=.growth.

import Observation

@Observable
final class AppNavigationState {
    /// 현재 선택된 탭 인덱스 (0 홈 / 1 대시보드 / 2 발달 / 3 설정).
    var selectedTab: Int = 0

    /// 발달 탭 진입 시 전환할 세그먼트. 발달 화면이 반영 후 nil로 소비한다.
    var developmentSegment: DevelopmentSegment?
}
