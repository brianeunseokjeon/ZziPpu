# 대시보드 달력 캐싱 전략 — 권고 제안서

> 상태: 제안(구현 전) · 작성: 아키텍처 리뷰 · 코드 변경 없음(문서만)
> 대상: `zzippu/Feature/Dashboard/CalendarViewModel.swift` 의 월별 캐싱 정책

---

## 0. TL;DR (권고안)

**옵션 B(SWR + 디스크 영속)를 권고**한다. 단, 사용자가 상상한 "진짜 델타(변경분만 서버에서 받아 패치)"는 **불필요**하다.
"변경분만 수정"의 실질은 **디스크 스냅샷으로 즉시 그리기 + 백그라운드 전월(全月) 재조회 + SwiftUI diff가 바뀐 셀만 재렌더**로 이미 달성된다. 백엔드 변경은 **0**.

> **중요한 전제(코드 확인됨):** 오프라인 모드에서 달력의 수유 총량은 **네트워크가 아니라 로컬 SwiftData**에서 온다(`SyncingFeedingRepository.dailyTotals` → `local.dailyTotals`). 즉 "달력이 API를 매번 호출한다"는 서술은 **serverOnly 모드에서만** 참이다. 이 사실이 옵션 C의 ROI를 더 떨어뜨린다(아래 §1.1).

---

## 1. 배경과 현재 상태

### 1.1 데이터 출처 (핵심 사실)
달력 셀 값의 두 축:

| 데코 | 출처 | 네트워크 |
|---|---|---|
| **검진 밴드/배지** | 생일 기반 순수계산(`CheckupDecorationProvider`) | **0 (계산만)** |
| **수유 총량**(`primaryValue`) | `FeedingRepository.dailyTotals(from:to:)` — 42칸 범위 1쿼리 | **모드에 따라 다름** |

`dailyTotals`의 실제 경로(`AppContainer` 확인):
- **offline 모드**: `SyncingFeedingRepository.dailyTotals` → `LocalFeedingRepository`(SwiftData 단일 범위쿼리, N+1 없음). **네트워크 0.**
- **serverOnly 모드**: `RemoteFeedingRepository.dailyTotals` → API 1회.

→ **캐싱의 유일한 최적화 대상은 "수유 총량"이며, offline 모드에서는 이미 로컬 쿼리라 서버 호출조차 없다.** 검진은 캐싱 대상이 아니다(계산이 캐시보다 빠르거나 대등).

### 1.2 현행 캐시 (`CalendarViewModel`)
- `monthCache: [Date: MonthCalendarModel]` — **세션 메모리**만.
- `loadCurrentMonth()`: 캐시 히트 → 그대로 사용(**재조회 안 함**). 미스 → `buildCalendar`(수유 범위쿼리 + 검진 계산).
- `invalidateCurrentMonthCache()`: 새 기록 저장/당겨서새로고침 후 **현재 월만** 무효화 후 재빌드.

### 1.3 한계
1. **디스크 미영속** — 앱 재시작 시 모든 월 재빌드(콜드스타트 시 첫 표시 지연·스피너).
2. **재방문 월 서버 재대조 없음** — 히트하면 그대로 → 다른 기기/세션 변경이 반영 안 됨(**stale**). offline 모드에선 로컬이 sync로 갱신되므로 위험 낮음, serverOnly에선 stale 가능.
3. **델타 없음** — 월 전체를 다시 계산. (단 42칸 1쿼리라 비용이 낮음.)

### 1.4 이미 있는 자산 (재사용/일관화)
- `DashboardSnapshotStore`(프로토콜) + `FileDashboardSnapshotStore`: `Caches/dashboard-{babyId}.json`, **SWR: hydrate→fetch→save**, 동기 load(콜드스타트 즉시), 백그라운드 atomic save, 디코드 실패→nil 폴백. → **동일 철학으로 `CalendarSnapshotStore` 신설**하면 됨.
- `DashboardViewModel.loadAll`: 옵셔널 주입(`store=nil`이면 no-op, 기존 동작과 바이트-동일) — **결합도 낮은 주입 패턴의 레퍼런스**.

---

## 2. 옵션 비교표

| 축 | **A. 현행(메모리만)** | **B. SWR+디스크 (권고)** | **C. 진짜 델타(changed-since)** |
|---|---|---|---|
| 정확성(staleness) | △ 세션 중 stale, 재시작 시 초기화 | ○ 진입 시 백그라운드 전월 재대조로 최신화 | ◎ 변경분 즉시·정밀 |
| 콜드스타트 첫 표시 | △ 매번 재빌드(스피너) | ◎ 디스크 즉시 표시(무-스피너) | ◎ 디스크 즉시 + 델타만 |
| 서버 호출량 | offline 0 / serverOnly 진입마다 1 | offline 0 / serverOnly 진입마다 1(백그라운드) | 변경분 있을 때만(이론상 최소) |
| 렌더 비용 | 전체 재빌드 후 diff | SWR 후 **SwiftUI diff = 바뀐 셀만** | 동일 |
| 구현 복잡도 | 없음(현행) | **낮음**(기존 패턴 복제) | **높음**(커서·병합·정합 로직) |
| **백엔드 영향** | 없음 | **없음(0)** | **신규 엔드포인트 필수** |
| 오프라인 정합 | 로컬쿼리와 무모순 | 로컬쿼리·sync와 무모순 | 로컬-델타 이중 진실원 → 정합 부담 |
| 월 전환 UX | 미스 시 스피너 | 캐시 즉시 + 조용한 갱신 | 동일 |

**판정: B.** A는 재시작·stale을 방치. C는 이득(수유 총량 재조회는 42칸 1쿼리로 이미 저렴)에 비해 백엔드 신규 API·이중 진실원 정합 비용이 과도 → **ROI 낮음, 과설계**. 특히 offline 모드에선 그 재조회조차 로컬이라 델타의 의미가 거의 소멸.

> **"변경분만 수정"의 냉정한 해석:** 사용자가 원하는 체감(재조회 티 안 나고 바뀐 칸만 갱신)은 **네트워크 델타가 아니라 렌더 델타**로 충분히 달성된다. SwiftUI는 `MonthCalendarModel`을 통째로 교체해도 `CalendarDay.id`(KST 자정) 기준 diff로 **값이 바뀐 셀만** 다시 그린다. 따라서 "변경분만"의 실질 = **디스크 SWR + SwiftUI diff**.

---

## 3. 권고안(B) 상세 설계

### 3.1 저장소 인터페이스
`DashboardSnapshotStore`와 동일 철학. 키에 **월**을 추가.

```
protocol CalendarSnapshotStore {
    func load(babyId: UUID, month: Date) -> CalendarSnapshot?
    func save(_ snapshot: CalendarSnapshot, babyId: UUID, month: Date)
    func clear(babyId: UUID)                 // 로그아웃/아기 전환 시 전체 정리
}

final class FileCalendarSnapshotStore: CalendarSnapshotStore {
    // Caches/calendar-{babyId}-{yyyyMM}.json
    // 동기 load(작은 JSON) + 백그라운드 atomic save + 디코드 실패→nil
}
```

### 3.2 스냅샷 모델 (Codable)
`MonthCalendarModel` 전체를 그대로 저장하지 **않는다**. 이유: 검진 데코는 생일 기반 순수계산이라 **재계산이 더 싸고 항상 정확**(스냅샷에 굳혀두면 오히려 stale). 저장 대상은 **네트워크/DB 원천인 수유 총량만**.

```
struct CalendarSnapshot: Codable, Sendable {
    let month: Date                 // 해당 월 첫날(KST 자정)
    let volumes: [DateVolume]       // 42칸 범위 수유 총량(= dailyTotals 결과)
    let savedAt: Date
}
```

→ hydrate 시 **`volumes`(캐시) + 검진(즉시 계산)** 를 합쳐 `MonthCalendarModel` 재조립. 스냅샷 축소로 디스크·정합 부담 최소.

### 3.3 흐름 (hydrate → fetch → save), `loadCurrentMonth()` 개편
```
1) 메모리 monthCache 히트 → 즉시 사용 후 (오늘 월이면) 백그라운드 재대조로 진행
2) 미스 → CalendarSnapshotStore.load(babyId, month) 동기 로드
     - 있으면: volumes + 검진계산 합성 → 즉시 표시(스피너 X, calendarModel 세팅)
     - 없으면: isLoading = true (최초 진입만 스피너)
3) 백그라운드: buildCalendar(수유 dailyTotals 재조회 + 검진) → calendarModel 갱신
     → SwiftUI diff가 바뀐 셀만 재렌더
4) 성공 시: 메모리 캐시 + CalendarSnapshotStore.save(volumes, month) 저장
   store=nil 이면 2)·4) 통째로 no-op → 현행과 동일(안전 강등)
```

### 3.4 무효화 (`invalidateCurrentMonthCache` 확장)
새 기록 저장/당겨서새로고침 시:
- 메모리 캐시 제거(현행 유지) **+ 디스크 스냅샷도 갱신되도록** `loadCurrentMonth` 재실행(3·4단계에서 save가 최신 volumes로 덮어씀).
- 별도 삭제 API 불필요 — **재조회 후 save가 곧 갱신**. (기록은 대개 오늘 월 → 그 월만 갱신되면 충분.)

### 3.5 최신성(TTL) 정책
- **TTL 없음, 대신 "진입 시 항상 백그라운드 재대조"**(오늘 월). 스냅샷은 "즉시 표시용 최근값"일 뿐, 진실원은 재조회 결과. → stale 창(window)이 화면 첫 프레임 한 순간으로 최소화.
- **과거 월**(잘 안 변함): 메모리 히트 시 재대조 생략 가능(옵션). 최초 표시는 디스크 스냅샷 → 백그라운드 1회 재대조 후 이후 세션 스킵. 비용 절감.
- **오늘 월 우선**: 오늘 월은 매 진입 재대조(기록이 가장 활발).

### 3.6 월 이동 프리페치
**보류(1차 범위 밖).** 42칸 1쿼리라 인접월 스피너가 짧고, 프리페치는 캐시 정리·수명 복잡도를 키움. 필요 시 후속. 권고: **하지 않음(YAGNI)**.

### 3.7 결합도
- `CalendarViewModel(... , snapshotStore: CalendarSnapshotStore? = nil)` **옵셔널 주입**.
- `AppContainer`에서 `FileCalendarSnapshotStore()` 주입, `DashboardView`가 전달.
- 제거하려면 주입만 빼면 현행으로 무손실 롤백(`DashboardSnapshotStore`와 동일 철학).

---

## 4. 정확성 가드
- **stale 최소화**: 진입 시 반드시 백그라운드 재대조(오늘 월). 스냅샷은 첫 프레임 즉시성 용도.
- **오늘 월 우선**: 항상 재대조, save.
- **과거 월**: 최초 1회 재대조 후 메모리 히트면 스킵(변동 드묾). 새 기록이 과거일에 꽂히면 `invalidate`가 해당 월 갱신.
- **검진 데코는 캐시 금지** — 항상 계산(생일만 있으면 항상 정확, stale 불가능).
- **offline 정합**: `dailyTotals`가 로컬 sync 결과를 이미 반영 → 스냅샷은 "직전 로컬 스냅"일 뿐, 재대조가 로컬 최신을 덮음. 이중 진실원 없음.

## 5. 엣지 케이스
- **babyId 스코프**: 파일명·키에 babyId 포함(`calendar-{babyId}-{yyyyMM}.json`). 아기 간 오염 불가.
- **로그아웃/아기 전환**: `CalendarSnapshotStore.clear(babyId:)`로 해당 아기 파일 삭제. (전체 로그아웃 시 Caches 전체 정리 훅과 정합 — `DashboardSnapshotStore` 정리 지점과 동일 위치에서 호출.)
- **디스크 용량**: 월당 1파일. 상한 정책 — **아기당 최근 N개월(예 24)만 유지**, save 시 초과분 오래된 순 삭제(경량 GC). 검진 상한(생일+72개월)과 무관하게 실제 방문 월만 쌓이므로 실사용 파일 수는 적음.
- **디코드 실패**: `load`가 `nil` 반환(크래시 금지) → 캐시 미스로 처리, 정상 재빌드. (스키마 변경 시 자동 폐기 효과.)
- **월 경계/타임존**: 모든 키·집계 KST 자정 기준(현행 `Calendar.kst`와 동일). `DateVolume.day`도 KST 자정.

## 6. 개발 태스크 (S1~S6) · 백엔드 무변경

> **백엔드 변경 없음(0).** 전량 iOS 클라 작업.

- **S1**: `CalendarSnapshot`(Codable) + `CalendarSnapshotStore` 프로토콜 정의.
- **S2**: `FileCalendarSnapshotStore` 구현(`FileDashboardSnapshotStore` 복제: 동기 load / 백그라운드 atomic save / 디코드 nil 폴백 / babyId+월 키 / N개월 GC / `clear`).
- **S3**: `CalendarViewModel`에 `snapshotStore: CalendarSnapshotStore? = nil` 옵셔널 주입. `loadCurrentMonth` 를 hydrate→fetch→save 로 개편(§3.3). 스냅샷은 volumes만, 검진은 항상 계산·합성.
- **S4**: `invalidateCurrentMonthCache`가 재조회 후 save로 스냅샷까지 갱신되게 확인.
- **S5**: `AppContainer`/`DashboardView` 와이어링 + 로그아웃·아기전환 시 `clear` 호출 지점 연결.
- **S6**: 테스트 — (a) 콜드스타트 hydrate 무-스피너, (b) 재대조로 stale 갱신 시 바뀐 셀만 반영, (c) 디코드 실패 폴백, (d) store=nil no-op(현행 동일), (e) offline/serverOnly 양 모드 정합.

## 7. 리스크
- **낮음**: 옵셔널 주입이라 무손실 롤백. 기존 SWR 패턴 재사용으로 신규 개념 없음.
- **주의**: hydrate(캐시)와 재대조(진실) 사이 **가짜 데이터 잔상** — 재대조를 진입 즉시 발사해 창을 최소화. 실패 시 stale 유지(대시보드 정책과 동일).
- **주의**: 스냅샷에 검진을 굳히지 말 것(생일 변경/D-day 변화가 stale 됨). volumes-only 원칙 준수.
- **과설계 경계**: 프리페치·TTL·델타는 넣지 않는다. 필요 신호가 관측된 뒤 후속.
