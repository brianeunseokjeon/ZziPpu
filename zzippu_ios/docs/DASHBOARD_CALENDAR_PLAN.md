# 대시보드 달력 기획서 (Dashboard Calendar)

> 상태: 초안 v1 · 작성: PM · 대상 레포: `zzippu_ios` (SwiftUI, 클린5레이어)
> 원칙: **읽기 전용(read-only) 월 달력**, 대시보드 최상단. iOS 캘린더 앱 스타일. 확장 가능 구조 필수.
> 후속: 이 문서를 디자인/개발 에이전트가 이어받음. 표현(색/폰트 픽셀)은 미확정으로 남김 — 정보구조·동작·데이터·확장성에 집중.

---

## 1. 범위 / 유저 스토리

### 목적·가치
- 부모가 **한 달 흐름을 한눈에** 본다. 개별 기록(오늘 요약, 추세 카드)은 "지금/최근"에 강하다면, 달력은 **월 단위 리듬과 예정 이벤트(검진)** 를 보완한다.
- **입력이 아니라 결과 조망**이 목적. 대시보드 상단에서 "이번 달 잘 먹었나 / 곧 무슨 검진이 있나"를 즉시 파악.

### 유저 스토리
- US-1: 부모로서 **날짜 칸 아래 그날 총 수유량(ml)** 을 봐서 컨디션이 나빴던 날/많이 먹은 날을 식별하고 싶다.
- US-2: 부모로서 **‹ 이전달 / 다음달 ›** 로 이동해 과거 흐름을 되짚거나 앞으로의 검진 창을 미리 보고 싶다.
- US-3: 부모로서 달력에서 **다가오는 영유아 검진(N차)과 그 기간·D-day** 를 놓치지 않고 싶다.
- US-4(미래): 부모로서 수유·검진 외에 **추가 지표 2종**(예: 수면 총량, 예방접종)도 같은 달력에서 보고 싶다 → 확장 구조로 대비.

### 배치
- `DashboardContentView`의 `LazyVStack` **최상단(현재 ① TodayInsights보다 위)** 에 `DashboardCalendarSection` 삽입. 나머지 카드 순서는 불변.

---

## 2. 달력 UX 명세

### 월 헤더
- 형식: `‹  2026년 7월  › `. 좌/우 chevron = 이전/다음달.
- **"오늘로" 복귀**: 채택. 현재 보는 달이 이번 달이 아닐 때만 헤더 우측(또는 월 텍스트 탭)에 "오늘" 액션 노출. 이번 달을 보고 있으면 숨김.
- 이동 범위 하한: 아기 **생일이 속한 달** 이전으로는 못 감(이전 chevron 비활성). 상한: 현재 달 이후로는 **검진 8차 창을 포함하는 미래까지 허용**(예방·확장 대비). 최소 상한 = "오늘"이 아니라 "8차 검진 end가 속한 달". → 하한/상한 밖 chevron은 disabled.

### 그리드
- 요일 헤더: **일~토**, 주 시작 = **일요일**(`Calendar.kst`의 firstWeekday를 1로 고정, 시스템 로캘 무시).
- 6주 × 7 = **최대 42칸** 고정 그리드(월마다 높이 튐 방지). 해당 월에 속하지 않는 **넘침칸(이전/다음달 며칠)** 은 흐리게(dimmed) 표시하되 날짜 숫자는 보여줌. 넘침칸에는 데코레이션(수유량/검진)을 **표시하지 않음**(그 달 데이터만).

### 날짜 칸 구성
```
┌─────────┐
│   12    │  ← 날짜 숫자 (오늘이면 강조: 원형 배경 등)
│   720   │  ← 그날 총 수유량 (숫자만; 단위 ml는 칸에서 생략)
│  · ▔▔   │  ← 검진 등 데코레이션 슬롯(2절 3항 참조)
└─────────┘
```
- **총 수유량 표기**: 칸에는 **숫자만**(예 `720`). `ml`은 칸마다 붙이면 시각적 노이즈 → **달력 하단 범례에 "숫자 = 하루 총 수유량(ml)" 1회 명시**.
- **데이터 없는 날**: 수유 기록 0건 → 수유량 줄 **공란**(0 표기 안 함; "기록 없음"과 "0ml"를 구분하기 위해). 향후 접종 등도 없으면 칸은 날짜 숫자만.
- **미래 날짜**: 수유량 없음(공란). 단 **검진 창은 미래여도 표시**(예정 이벤트이므로). 미래 칸 자체를 흐리게 하진 않음(검진 가독성 유지) — 오늘만 강조.
- **오늘 강조**: 날짜 숫자에 강조 스타일(원형 채움 등, 디자인에서 확정). 넘침칸/미래와 구분.

---

## 3. 영유아 검진 표시 방식 (핵심 결정)

### 문제
검진 창(window)은 **여러 달에 걸침**. 예) 2026-04-22생 → 2차 = 2026-08-22~2026-11-21(약 3개월), 3차 = 2027-01-22~2027-05-21. 월 달력 한 화면엔 창의 일부만 보임.

### 대안 비교

| 안 | 방식 | 장점 | 단점 |
|----|------|------|------|
| (a) 창 전체 배경 강조 | 창에 걸친 모든 날짜 칸 배경 톤 | 기간감 직관적 | 3개월 = 달마다 큰 색면 → 수유량 숫자 가독성 저하, 여러 창 겹치면 혼란 |
| (b) 시작일 뱃지/라벨 | 창 **시작일 칸에만** "N차" 점/라벨 | 캘린더앱 이벤트처럼 깔끔, 겹침 적음 | 창이 "기간"임이 안 보임(시작일만 콕) |
| (c) 상/하단 요약 | 달력 밖에 "다가오는 검진: N차 D-6" | 액션성 높음, 화면 어디서나 정보 | 달력 그리드 자체엔 검진 위치 안 보임 |

### 권장 (택1 = 하이브리드 b + c, a는 경량화)
> **(b) 시작일 라벨 + (c) 요약 배너**를 채택하고, (a)는 **"밑줄/얇은 언더바"로 경량화**해 창 구간을 은은히 표시.

- **(b) 시작일 라벨**: 검진 창 **start 날짜 칸**에 작은 점 + "N차" 라벨(캘린더앱 이벤트 도트 참고). 한 화면에 창 시작이 없으면 라벨도 없음(정상).
- **(a-lite) 창 언더바**: 창에 걸친 날짜 칸 **하단에 얇은 색 바(underline)**. 배경 채움(x) → 색면 부담 없이 "이 날들은 검진 가능 기간"임을 표현. 창 첫날/끝날에서 바를 둥글게(캡슐 끝) 처리하면 시작/끝 인지 가능.
- **(c) 요약 배너**: 달력 **하단**에 "다가오는 검진: **N차 · D-day** (기간 M/D~M/D)" 1줄. 오늘 기준 가장 가까운 미래(또는 진행 중) 검진 1개. 진행 중이면 "N차 · 진행 중 (D-day: 마감까지 12일)".
- **색상·범례**: 검진 = 단일 강조색(도트/언더바/배너 동일 색). 범례에 "● N차 검진 기간" 1항. 실제 색 hex는 디자인에서 theme 토큰으로 확정(예: `theme.color.domain...`) — 여기선 "검진 계열 1색" 으로만 규정.

### 검진 창 계산(확정 사실 — 그대로 사용)
- 8개 차수. start = 생일 + A개월, **end = 생일 + (B+1)개월 − 1일**. 1차만 일 기준(생일+14일 ~ 생일+35일).

| 차수 | A~B | start | end |
|------|-----|-------|-----|
| 1 | 14~35일 | 생일+14일 | 생일+35일 |
| 2 | 4~6개월 | 생일+4개월 | 생일+7개월−1일 |
| 3 | 9~12개월 | 생일+9개월 | 생일+13개월−1일 |
| 4 | 18~24개월 | 생일+18개월 | 생일+25개월−1일 |
| 5 | 30~36개월 | 생일+30개월 | 생일+37개월−1일 |
| 6 | 42~48개월 | 생일+42개월 | 생일+49개월−1일 |
| 7 | 54~60개월 | 생일+54개월 | 생일+61개월−1일 |
| 8 | 66~71개월 | 생일+66개월 | 생일+72개월−1일 |

- 전부 `Calendar.kst` 기준(`Shared/Extensions/Calendar+KST.swift`). `date(byAdding:.month/.day, ...)` 로 산출.
- 검증됨: 2026-04-22생 → 2차 08-22~11-21, 3차 2027-01-22~05-21 일치.

---

## 4. 확장 구조 (중요) — 날짜 데코레이션 플러그인

### 개념
날짜 칸에 **얹히는 정보 = 데코레이션(decoration)**. 지금 2종(수유량 텍스트, 검진 표시), 미래 2종을 **코드 변경 최소**로 추가하려면 "날짜당 무엇을 그릴지"를 도메인이 산출하고, View는 표현만 한다.

### 도메인 모델(제안 — Foundation only)
```swift
// Domain/Entities/Calendar/CalendarDayDecoration.swift
enum CalendarDecorationSlot {          // 칸 내 위치 슬롯 (겹침 방지)
    case primaryValue     // 날짜 밑 큰 숫자 (수유량이 여기)
    case eventBadge       // 도트+라벨 (검진 시작일)
    case underbar         // 하단 얇은 바 (검진 창 구간)
    case footnote         // 예약 슬롯(미래)
}

enum CalendarDecorationKind: String {  // 어떤 도메인인가 (범례·색 매핑 키)
    case feedingVolume
    case checkupWindow
    // 미래: case sleepTotal / case vaccination ...
}

struct CalendarDayDecoration: Identifiable {
    let id: UUID
    let date: Date               // KST 자정 기준 날짜
    let kind: CalendarDecorationKind
    let slot: CalendarDecorationSlot
    let text: String?            // 예: "720", "2차"
    let spanRole: SpanRole?      // 구간 데코 전용: .start/.middle/.end/.single
    // 색/폰트는 담지 않음 — View가 kind→theme 토큰 매핑 (DS는 Domain 비의존 원칙 준수)
}
enum SpanRole { case single, start, middle, end }
```

### Provider 추상화 (플러그인 지점)
```swift
// Domain/UseCases/Calendar/CalendarDecorationProvider.swift
protocol CalendarDecorationProvider {
    var kind: CalendarDecorationKind { get }
    /// 주어진 월(날짜 배열)에 대해 날짜별 데코레이션 산출
    func decorations(forMonthDays days: [Date], baby: Baby) async throws -> [CalendarDayDecoration]
}
```
- 지금 2개 구현:
  - `FeedingVolumeDecorationProvider` — 월 수유량 집계(5절) → 날짜별 `primaryValue` 텍스트.
  - `CheckupDecorationProvider` — 생일로 8차 창 계산 → `eventBadge`(start) + `underbar`(구간).
- 미래 2개는 **같은 프로토콜 구현 하나만 추가**하고 `providers` 배열에 등록 → View/집계 로직 무변경.

### 오케스트레이션 UseCase
```swift
// Domain/UseCases/Calendar/BuildMonthCalendarUseCase.swift
struct BuildMonthCalendarUseCase {
    let providers: [CalendarDecorationProvider]   // DI로 주입 (확장 = 배열에 추가)
    func callAsInterface(month: Date, baby: Baby) async -> MonthCalendarModel
    // 1) month → 42칸 날짜 그리드 생성(KST, 일요일 시작)
    // 2) 각 provider 병렬 호출 → 데코 합침
    // 3) 날짜별로 slot 정리 → 뷰용 MonthCalendarModel 반환
    // 4) 다가오는 검진 요약(배너)도 여기서 계산해 모델에 포함
}
```
- **클린아키텍처 정합**: Domain UseCase가 "날짜별 무엇을 그릴지"를 완성해 넘김. `CalendarViewModel`(Feature)은 상태(현재 월)·이벤트(월 이동)만, `CalendarSectionView`(DS/Feature)는 모델을 **표현만**. Design System 컴포넌트는 Domain 타입 대신 색 없는 뷰 DTO를 받음(기존 `DSDonutSegment` 패턴과 동일: 도메인 튜플 → DS 세그먼트 매핑).

### 확장 시나리오(미래 2종) 예
- "수면 총량": `SleepTotalDecorationProvider` 추가 → `primaryValue`와 슬롯 충돌 → **표시 모드 토글**(수유량/수면 중 택1) 또는 `footnote` 슬롯 사용. → 슬롯 enum이 충돌을 명시적으로 드러내므로 설계 시 결정 가능.
- "예방접종": `VaccinationDecorationProvider` → `eventBadge`(검진과 색만 다름). 검진과 동일 메커니즘 재사용.

---

## 5. 데이터 전략

### 월 수유량 집계 — **신규 range API 권장 (채택)**
현행 `FeedingRepository.list(babyId:, on:)` 는 하루 단위. 42칸 = 최대 42회 호출은 **비효율 + N+1**. → **범위 집계 API 신설** 권장.

제안 시그니처(택1):
```swift
// A안: 원자료 범위 조회 (뷰/유즈케이스에서 날짜별 합산)
func list(babyId: UUID, from start: Date, to end: Date) async throws -> [Feeding]

// B안: 집계 결과 반환 (권장 — 전송량↓, KST 합산을 Repo/로컬에서)
func dailyTotals(babyId: UUID, from start: Date, to end: Date) async throws -> [DateVolume]
struct DateVolume { let day: Date; let totalMl: Int }   // day = KST 자정
```
- **권장 = B안(`dailyTotals`)** + 로컬 우선. 이유:
  - 오프라인 로컬(SwiftData)에 수유가 이미 있으므로 **로컬 범위 쿼리(predicate: babyId && start≤timestamp<end)** 한 번으로 42칸 커버 → 서버 왕복 0.
  - 서버 경로가 필요하면 range 엔드포인트 1회. 킬스위치/폴백(오프라인 계층)과 정합.
- **KST 경계**: "하루"는 `Calendar.kst`의 startOfDay~다음날 startOfDay. 집계 시 timestamp를 KST 날짜로 버킷팅. 월 그리드 start/end도 넘침칸 포함 42칸의 첫날~끝날로 잡아 한 번에 조회.
- 기존 `list(on:)`은 유지(하위호환) — range는 **추가**만.

### 캐싱 / 성능
- **월 이동 시 재조회**: 사용자가 이전/다음달 이동 → 그 달 42칸만 재계산. 로컬 쿼리라 저비용.
- **인접 월 프리페치(옵션)**: 이동 반응성 위해 현재±1달 선로드 가능(성능 여유 확인 후, S 단계 옵션).
- **대시보드 스냅샷 캐시와의 관계**: 기존 `dashboardSnapshotStore`는 "오늘/최근" 롤업 캐시. **달력은 월 단위 별개 관심사** → 스냅샷에 끼워넣지 말고 `CalendarViewModel`이 **자체 월 캐시(딕셔너리: month→MonthCalendarModel)** 보유. 상충 없음. 새 기록 저장 시 해당 월 캐시만 무효화(관찰 or pull-to-refresh 시 clear).
- 검진 데코는 **생일만 있으면 순수 계산** → 네트워크 0, 캐시 불필요(월 이동마다 재계산 저렴).

---

## 6. 엣지 케이스 / 접근성

| 상황 | 처리 |
|------|------|
| 생일 이전 달 | 이전 chevron 비활성(생일 속한 달이 하한). 생일 전 날짜 칸은 넘침칸처럼 무데코. |
| 아주 어린 월령(신생아) | 1차 검진만 임박. 배너 = 1차 D-day. 수유량은 정상 표시. |
| 큰 월령(6세±) | 8차까지 표시. 8차 end 이후엔 검진 데코 없음(정상), 배너는 "예정 검진 없음" 또는 숨김. |
| 검진 창 월 걸침 | underbar span(start/middle/end)로 연속성 표현. 월 경계에서 잘려도 각 달에 middle/end 조각 표시. |
| 빈 달(기록 전무) | 그리드·검진은 정상, 수유량 줄만 전부 공란. "이 달 기록 없음" 미세 안내(옵션). |
| 다크모드 | 넘침칸 dim, 오늘 강조, 검진색 모두 theme 토큰으로 라이트/다크 대응(디자인 확정). |
| 큰 글씨(Dynamic Type) | 칸이 좁아 수유량 3~4자리 + "N차" 겹침 위험 → 칸 내 텍스트는 **최소·1줄·축소 허용(minimumScaleFactor)**, 배너/범례는 풀 텍스트로 접근성 보완. VoiceOver: 칸 accessibilityLabel = "7월 12일, 수유 720ml, 2차 검진 기간". |
| 검진 겹침(드묾) | 슬롯 분리(eventBadge=start, underbar=구간)로 시각 충돌 최소화. 같은 날 2개 배지면 "+N". |

---

## 7. 범위 밖 (Out of scope)
- 달력에서 **기록 입력·수정·삭제** — 읽기 전용. 날짜 탭 시 상세 이동은 **이번 범위 밖**(후속: 탭→해당일 상세 딥링크 검토 가능).
- **수면·기저귀·놀이·성장** 등 타 도메인 데코 — 이번 미포함. 단 **4절 확장 구조로 후속 무리 없이 추가 가능**하도록만 대비.
- 검진 알림/푸시, 캘린더 앱 내보내기(EventKit), 다중 아기 동시 표시.

---

## 8. 개발 태스크 분해 (S1..Sn) & 리스크

| 단계 | 내용 | 산출 |
|------|------|------|
| **S1** | 도메인 스캐폴딩: `CalendarDayDecoration`, `CalendarDecorationProvider`, `MonthCalendarModel`, `BuildMonthCalendarUseCase`(providers 배열 DI) | Domain 타입/프로토콜 |
| **S2** | 검진 Provider: `CheckupDecorationProvider`(8차 창 계산, KST) + 단위테스트(2026-04-22 케이스 회귀) | 검진 데코 + 테스트 |
| **S3** | 수유 range API: `FeedingRepository.dailyTotals(from:to:)`(로컬 우선 구현 + 서버 폴백) + `FeedingVolumeDecorationProvider` | range API + 데코 |
| **S4** | Feature: `CalendarViewModel`(현재 월/이동/월캐시), `DashboardCalendarSection`(그리드·헤더·요약 배너) | 뷰모델+섹션 |
| **S5** | DS 컴포넌트: 42칸 그리드, 날짜 칸(숫자+값+슬롯), 요일헤더, chevron. 색 없는 DTO 수신 | 재사용 DS 컴포넌트 |
| **S6** | 통합: `DashboardContentView` 최상단 삽입, 범례, "오늘로" 복귀, 다크/Dynamic Type/VoiceOver | 통합·QA |
| **S7(옵션)** | 인접 월 프리페치, 진행중/다가올 검진 배너 다듬기 | 성능·폴리시 |

### 리스크
- **R1 칸 공간 부족**: 수유량 + 검진 라벨 + 큰 글씨 → 겹침. 완화: 슬롯 분리, minimumScaleFactor, 칸 내 축약·배너 위임.
- **R2 range API 이중경로**: 로컬/서버 합산 결과 불일치 가능. 완화: 오프라인 계층 킬스위치와 동일 정책 재사용, KST 버킷팅 단일화.
- **R3 스냅샷 캐시 오염**: 달력을 스냅샷에 넣으면 오늘 롤업과 결합↑. 완화: **별도 월 캐시**로 분리(5절).
- **R4 슬롯 충돌(미래 수면총량 vs 수유량 primaryValue)**: 완화: slot enum이 충돌을 명시 → 표시 모드 토글 설계.
- **R5 이동 범위 경계**: 생일 하한/8차 상한 off-by-one. 완화: S2 테스트에 경계 포함.

---

## 9. 핵심 의사결정 요약
1. **검진 표시 = (b)시작일 도트+"N차" 라벨 + (a-lite)창 하단 언더바 + (c)하단 "다가오는 검진 D-day" 배너** 하이브리드. 배경 색면(full-a)은 가독성 이유로 불채택.
2. **월 수유량 집계 = 신규 `FeedingRepository.dailyTotals(babyId:from:to:)` (집계 반환, 로컬 SwiftData 우선, 서버 폴백)** 채택. 42회 개별 호출·기존 `list(on:)` 반복 불가. 기존 API는 하위호환 유지, range는 추가만.
3. **확장 인터페이스 = `CalendarDecorationProvider` 프로토콜 + `CalendarDayDecoration`(kind/slot/spanRole) 모델 + `BuildMonthCalendarUseCase`(providers 배열 DI)**. 미래 2종은 Provider 구현 1개 추가 + 배열 등록만으로 View/집계 무변경. 색은 Domain이 아닌 View가 kind→theme 매핑(DS의 Domain 비의존 유지).
