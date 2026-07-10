# IA_4TAB.md — 먹놀잠/찌뿌둥 iOS 4탭 정보구조·화면 기획

> 대상: SwiftUI 네이티브(iOS 17.5+). 서버-우선(Remote 패턴, `DATA_STRATEGY_SERVER_FIRST.md`).
> 추구미: **Apple 건강(Health) 앱** — 요약 카드 → 상세 드릴다운, 그래프 우선, 깔끔한 카드 그리드.
> 화면은 **`design-system/COMPONENTS.md`의 18개 DS 컴포넌트 + Swift Charts**로 조립한다.
> 필드·엔티티·API는 `PRODUCT_SPEC.md`·`DATA_STRATEGY_SERVER_FIRST.md`를 **참조**(여기서 재기술 안 함).
> 이 문서가 `PRODUCT_SPEC.md §2`(구 5탭)를 **대체**한다.

---

## 1. 4탭 정의

| 탭 | SF Symbol | 목적 | 핵심 화면 | 상단 헤더 |
|---|---|---|---|---|
| **홈** | `house.fill` | 초저마찰 기록 허브 | BigActionGrid + 진행중 세션 배너 + 오늘 타임라인 | AppHeader(아바타+나이+날짜네비) |
| **대시보드** | `heart.text.square.fill` | 건강앱식 요약→상세 브라우즈. **대시보드+추세 통합** | 메트릭 카드 그리드 → 탭 시 상세 차트(Swift Charts) | AppHeader(날짜네비, 대시보드용) |
| **발달** | `figure.child` | 연령별 발달 이정표 + 예방접종 | 현재 스테이지 + 이정표 타임라인 + 접종 스케줄 | 단순 타이틀(날짜네비 없음) |
| **설정** | `gearshape.fill` | 프로필·공유·계정·내보내기 | 리스트(DSListRow) | 단순 타이틀 |

- 홈·대시보드에만 `selectedDate` 날짜 네비 공유(같은 날 기준). 발달·설정은 날짜 무관.
- `heart.text.square.fill`은 건강앱 감성을 위해 `chart.bar.fill` 대신 채택(추세 그래프까지 품는 통합 탭임을 시각적으로 암시).

### 1.1 기존 기능 → 4탭 매핑표

| 기존 기능(웹/구 IA) | 배치 | 비고 |
|---|---|---|
| feeding(수유) | **홈** 기록/타임라인 + **대시보드** 요약·차트 | 입력=홈, 집계=대시보드 |
| sleep(수면, 활성세션) | **홈**(배너+타임라인) + **대시보드** 차트 | 활성세션 배너는 홈 전용 |
| diaper(기저귀) | **홈** + **대시보드** 카드 | |
| play(놀이/터미타임) | **홈** + **대시보드**(터미타임 별도 집계) | |
| recording/timeline(기록 허브) | **홈** = 이 탭 자체 | 구 `/record` 탭 → 홈으로 통합 |
| dashboard(일일요약·예측) | **대시보드** 요약 섹션 | |
| trends(추세 주/월) | **대시보드** 상세 차트 기간토글로 통합 | **별도 탭 폐지** |
| growth(성장곡선) | **대시보드** 상세(성장 메트릭 카드→곡선) + 입력 진입 | 입력 위치는 §6 트레이드오프 |
| development(발달정보) | **발달** | 번들 정적 콘텐츠 |
| vaccination(예방접종) | **발달**(§6 근거) | |
| caregiver(공동양육 공유) | **설정** | 서버 있음 → MVP 포함 가능 |
| settings(프로필·계정) | **설정** | |
| ai-review/ai-chat/ai-saved/youtube-summary | **제외** | §3 |
| VoiceCommandHero(음성) | **제외(후순위)** | |

---

## 2. 화면별 구성 (DS 컴포넌트 + 차트)

### 2.1 홈 (기록 허브)
구 웹 `recording/components`를 그대로 이관. 위→아래:
1. **`AppHeader`** — BabyAvatar + 이름/나이 + `< 날짜 >` 네비(오늘이면 다음 비활성).
2. **`ActiveSessionBanner`** — 진행중 수면 세션. `DSCard(interactive)` + `DSStatusPill(info)` "수면 중 · 1:20". 탭 → 종료(PUT `/sleeps/{id}/end`). 활성 세션 없으면 미표시(`GET /sleeps/active`).
3. **BigActionGrid** — 2×2 큰 버튼(수유/수면/기저귀/놀이). `DSCard(interactive)` 4장 + 도메인색(`domain.*`) + SF Symbol. 탭 → 도메인 입력 바텀시트.
4. **QuickRepeatRow** — 마지막 분유량 원탭 반복 + Undo(스낵바). `DSChip(quick)` 행. 모유는 좌/우/양쪽 원탭.
5. **오늘 타임라인** — `DayTimeline`: `DSSectionHeader` + `TimelineGroupView`/`TimelineItemRow`(도트색=도메인, mono 시각, 최신 그룹 highlighted). 비었으면 `DSEmptyState`("이 날의 기록이 없어요").
   - 항목 탭 → `RecordEditSheet`(`.dsBottomSheet`, 수정/삭제).

**입력 바텀시트**(도메인별, `.dsBottomSheet`):
- 수유: `DSChip`(type 토글) + `DSNumberStepper`(amountMl, clamp 0~500) + QuickChips(100/120/150) + 저장 `Button(.ds(.primary))`.
- 수면: 시작(활성세션 생성)만. 종료는 배너에서.
- 기저귀: `DSChip`(pee/poo/both). poo면 색점(`stoolColor` hex) + 상태 선택(선택 안 해도 저장).
- 놀이: `DSChip`(playType) + `DSNumberStepper`(durationMinutes).

### 2.2 대시보드 (건강앱 통합 — 핵심)
**패턴: 메트릭 카드 리스트(요약) → 탭 → 상세 차트 화면(push).** 애플 건강의 "요약/브라우즈 → 상세" 그대로.

**요약 화면**(스크롤, 카드 그리드):
- **`AppHeader`**(날짜네비 공유) — 선택일 기준 집계.
- **다음 예상 카드**(`NextFeedingCard`): `GET /dashboard/predictions`. "다음 수유 ~14:30" 큰 숫자 + `DSStatusPill`. 상단 강조 카드.
- **수유 적정량 카드**(`FeedingAdequacyCard`): `DSGaugeBar(fillRatio:normalRange:tone:)` — 오늘 총 수유량 vs 가이드라인 밴드 + tone pill("적정"/"권장보다 적음").
- **메트릭 카드 그리드**(`DSCard(interactive)` 2열, 큰 숫자 + 미니 스파크라인 Swift Charts):
  | 카드 | 요약(큰 숫자) | 미니 그래프 | 탭 → 상세 |
  |---|---|---|---|
  | 수유 | 오늘 총 ml · 횟수 | 시간대별 막대 | 수유 상세(일 막대 + 주/월 추세) |
  | 수면 | 오늘 총시간 | 낮/밤 세그먼트 바 | 수면 상세(수면 패턴 + 추세) |
  | 기저귀 | 소/대 횟수 | 도트/막대 | 기저귀 상세(색·횟수 추세) |
  | 놀이/터미타임 | 총 분 · 터미타임 분 | 막대 | 놀이 상세 |
  | **성장** | 최신 체중/키/머리 | — | **성장곡선 상세(WHO 백분위)** |
  - 요약 수치 소스: `GET /dashboard/daily?date=`(서버 집계, 읽기전용).

**상세 화면(push)** — 카드 탭 시. 각 상세 = **큰 Swift Charts + 기간 토글 + 인사이트**:
- 상단 **기간 토글** `DSChip` 세그먼트(일/주/월) ← 구 `TrendRangeToggle` 흡수.
- **차트**(Swift Charts):
  - 수유/수면/기저귀/놀이: 선택 기간 `BarMark`/`LineMark` 추세 + 평균선.
  - **성장**: `LineMark` 3지표(체중/키/머리둘레) 시계열 + WHO 백분위 밴드(번들 기준곡선 오버레이). `GET /babies/{id}/growth`(전체 시계열).
- **`TrendInsightCard`**(`DSCard`) — 가이드라인 대비 문구(로컬 계산) + `DSStatusPill`.
- 성장 상세 우상단 **"+ 기록"**(`DSSectionHeader(withAction)`) → 성장 입력 시트(§6).

> 대시보드 요약↔상세 소스 정리: 요약=`dashboard/daily`+`predictions`(서버 집계), 추세=기간 데이터 클라 계산(구 `trendCalc`), 성장=`growth` 시계열+번들 WHO 곡선.

### 2.3 발달
1. **현재 스테이지 카드**(`StageDetail`): 나이(ageDays)로 조회. `DSCard` — grossMotor/fineMotor/cognition/language/social/selfCare + parentActions + warningSigns + sources. `GET /development/stages/current?age_days=`(인증 불필요) 또는 **번들 JSON**.
2. **이정표 타임라인**(`MilestoneTimeline`): `TimelineItemRow`(이모지+라벨) — celebration/checkup/developmental. 지난/현재/다가올 구분.
3. **예방접종 섹션**(`DSSectionHeader` + `VaccinationList`):
   - `DSListRow(withTrailing)` 행: 백신명·회차·예정일 + `DSStatusPill`(overdue=danger/임박=warning/완료=success). isOverdue·daysUntil = 로컬 계산.
   - 탭 → 접종 완료 시트(`administeredDate` + `hospitalName`) → POST `/vaccinations/{id}/administer`.
   - 스케줄 프리셋 = 번들 정적 JSON(생년월일 기준).

### 2.4 설정
`DSListRow(navigable)` 리스트:
- **아기 프로필** → 편집(이름/생년월일/성별/사진 photoUrl). PATCH `/babies/{id}`.
- **공동양육자 공유**(`CaregiverCard`): 초대코드 생성(POST `/caregivers/invite`) → 코드/만료 표시·공유시트. 멤버 목록(GET `/caregivers`). 합류는 로그인 시 코드 redeem.
- **데이터 내보내기**: `GET /babies/{id}/export?format=json|csv`(후순위, 링크만).
- **계정**: 로그아웃(토큰 폐기 + 세션 무효화), 약관/버전.
- AI 항목 **미노출**.

### 레이아웃 지침(건강앱 감성)
- 카드 그리드: 2열, 넉넉한 코너(radius xl), shadow-sm, 카드당 **큰 숫자 1개 + 미니 그래프**.
- 색은 색만으로 상태 전달 금지 → `DSStatusPill` 텍스트 병기.
- 상세는 항상 push(네비 스택), 입력은 항상 바텀시트. 이 규칙을 섞지 않는다.
- 과설계 금지: 미니 그래프는 축·범례 없는 스파크라인, 상세에서만 축·평균선·토글.

---

## 3. 제외/삭제 목록

| 항목 | 조치 | 이유(한 줄) |
|---|---|---|
| ai-review(오늘 리뷰) | 제외 | 서버 LLM 의존, 이번 IA 후순위 |
| ai-chat(소아과 상담) | 제외 | 서버 LLM 의존, 후순위 |
| ai-saved(저장 정보) | 제외 | ai-chat 종속 |
| youtube-summary | 제외 | 서버 LLM 의존, 후순위 |
| **추세(trends) 탭** | **삭제(통합)** | 대시보드 상세 차트+기간토글로 흡수(중복 탭 제거) |
| 구 `/record` 탭 | 삭제(통합) | 홈이 기록 허브 |
| VoiceCommandHero(음성) | 제외 | 후순위, MVP 초저마찰은 버튼그리드로 충분 |
| "더보기/AI 세그먼트" | 삭제 | AI 숨김 → 세그먼트 불필요, 4탭으로 축소 |
| ModeToggle/RecordPopover(웹 전용 UX) | iOS 네이티브로 대체 | iOS는 바텀시트·contextMenu 관용구 사용 |

---

## 4. 네비게이션 / 라우팅

```
AppRootView (무변경 분기 — PRODUCT_SPEC §2.1)
 ├ accessToken==nil        → AuthFlow
 ├ termsRequired           → TermsAgreementView
 ├ 서버 아기 없음(GET /babies 빈 결과) → OnboardingView
 └ else                    → MainTabView (4탭)
      ├ 홈        NavigationStack → [입력 BottomSheet] · [RecordEditSheet]
      ├ 대시보드  NavigationStack → 상세 차트(push) → 성장입력 Sheet
      ├ 발달      NavigationStack → 접종완료 Sheet
      └ 설정      NavigationStack → 프로필편집(push) · 공유 Sheet
```
- **규칙**: 입력/편집 = `.dsBottomSheet`(모달), 상세 열람 = `NavigationStack` push. 탭별 독립 스택.
- 온보딩 분기 기준은 **서버 `GET /babies`** 결과(로컬 아님) — essy1224 빈 화면 방지(DATA_STRATEGY §2).
- `selectedDate`는 홈·대시보드가 공유하는 앱 수준 상태(탭 전환해도 유지).

---

## 5. 개발 순서 (수직 슬라이스)

`MIGRATION_PLAN.md §6`의 Remote 3점세트(DTO/DataSource/Repository) 패턴을 각 슬라이스에 적용. UI는 위 DS 조립.

| # | 슬라이스 | 산출 | 완료 기준 |
|---|---|---|---|
| **T1** | 4탭 셸 + 홈 기록 | `DSTabBar` 4탭, 홈(AppHeader+BigActionGrid+타임라인), Feeding Remote(기존 S3 기준 슬라이스) | essy1224 로그인 → 서버 수유 타임라인 표시·저장 iOS↔웹 반영 |
| **T2** | 홈 나머지 도메인 | sleep(활성세션 배너)·diaper·play Remote 3점세트 | 4종 기록·타임라인·편집·삭제 동작 |
| **T3** | 대시보드 요약 | `dashboard/daily`+`predictions` 읽기, 메트릭 카드 그리드 + GaugeBar | 선택일 요약 카드 표시(읽기전용) |
| **T4** | 대시보드 상세 차트 | Swift Charts 상세 + 기간토글(구 trendCalc) | 카드 탭 → 주/월 추세 차트 |
| **T5** | 성장 | Growth Remote + 성장곡선(WHO 밴드) + 입력 시트 | 시계열·곡선 표시, 온보딩 출생체중이 서버 growth로 생성 |
| **T6** | 발달 + 예방접종 | 번들 development JSON + vaccination Remote(list/administer) | 현재 스테이지·이정표 표시, 접종 완료 체크 반영 |
| **T7** | 설정 + 공유 | 프로필 편집(PATCH), caregiver invite/join | 배우자 코드 합류 후 같은 아기 공유 |

**최소 성공 경로**: T1→T2→T3. T1 완료 시 핵심 기록 루프 + 빈 화면 문제 동시 해결.

---

## 6. 결정 필요 트레이드오프

### 6.1 예방접종 위치 → **발달 탭** (권장)
- 근거: 접종은 "연령 기반 스케줄 + 발달 체크업"으로 발달 이정표(checkup 마일스톤)와 **같은 멘탈모델**. 건강앱도 예방접종을 건강 요약이 아닌 별도 헬스 레코드로 둠. 설정에 넣으면 "매일 안 보는 관리 항목"으로 파묻힘 → 발달 탭이 재방문 동선에 맞음.
- 대안: 대시보드 "다가올 접종" 요약 카드만 두고 상세는 발달. → **채택 가능한 절충**(요약 진입점은 대시보드, 관리 화면은 발달).

### 6.2 성장 입력 위치 → **대시보드 성장 상세 내 "+ 기록"** (권장)
- 근거: 성장은 매일 기록이 아니라 곡선을 보며 가끔 입력 → "차트를 보다가 그 자리에서 추가"가 자연스러움(건강앱 패턴). 홈 BigActionGrid에 넣으면 매일 4종 기록의 초저마찰을 희석.
- 대안: 홈 QuickRepeatRow 옆 보조 진입점 추가. → 접근성 vs 홈 단순성 트레이드오프. **MVP는 대시보드 단일 진입 권장.**

### 6.3 caregiver MVP 포함 여부
- 서버 EP 존재(invite/join) → 기술적으로 MVP 가능. 단 공유는 "핵심 가치"라 T7로 배치하되, 기록 루프(T1~T5) 안정화 후 착수 권장.

### 6.4 대시보드 요약 소스: 서버 집계 vs 클라 계산
- 요약(daily/predictions)은 **서버 집계 사용**(중복 로직 방지, 읽기전용). 추세(주/월)만 클라 계산(구 trendCalc) — 서버에 기간 추세 EP 없음. 성장 WHO 밴드는 번들 정적.
