# PRODUCT_SPEC.md — 먹놀잠/찌뿌둥 iOS 제품 명세

> 출처: 기존 웹앱(`frontend/src/features`, `frontend/src/app`) 전수 조사 기반.
> 대상: SwiftUI 네이티브(iOS 17.5+, bundle `jstyle.com.zzippu`).
> 이 문서는 "무엇을 만드는가(기능·데이터·화면흐름)"를 정의한다. "어떻게(레이어·폴더)"는 ARCHITECTURE.md, "데이터 저장·동기화"는 DATA_STRATEGY.md 참조.

---

## 0. 제품 한 줄 정의
신생아(0~24개월) 육아 기록 앱. 수유·수면·기저귀·놀이·성장·예방접종을 **초저마찰(2탭 이내)** 로 기록하고, 대시보드/추세/발달정보로 되먹임하며, AI 소아과 리뷰/상담으로 안심을 제공한다.

핵심 사용자: 신생아 아빠(개발자). 한 손 조작, 밤중 수유 중 어두운 화면, 초 단위로 빠른 기록이 최우선 UX 가치.

---

## 1. 도메인 전수 조사

각 도메인은 웹 `features/<domain>/types` 의 TypeScript 인터페이스를 근거로 정리했다. 필드명은 iOS에서 camelCase 그대로 사용(웹 API-client가 snake_case→camelCase 변환하던 것을 iOS는 로컬 저장이므로 처음부터 camelCase).

### 1.1 auth (인증) — **유일하게 서버를 쓰는 도메인**
- 방식: 이메일 OTP → JWT 발급. 공동양육자는 초대코드(1회용) redeem 로그인.
- API (auth-service, 별도 baseURL):
  - `POST /api/v1/auth/email/request` `{ email }` → 204 (OTP 발송)
  - `POST /api/v1/auth/email/verify` `{ email, code }` → `{ accessToken, tokenType, userId, isNewUser, termsRequired }`
  - `POST /api/v1/auth/code/redeem` `{ code }` → `{ accessToken, userId, babyId, isNewUser, termsRequired }` (공동양육자)
  - `GET /api/v1/auth/terms` → `TermDoc[]` (`type: service|privacy`, version, title, content, required)
  - `POST /api/v1/auth/terms/agree` `{ agreements: [{type, version}] }` → 204 (Bearer 필요)
- 세션 상태: `accessToken`, `userId`, `isNewUser`, `termsRequired`.
- iOS 저장: **accessToken은 Keychain**, 나머지 플래그는 UserDefaults/@AppStorage. (DATA_STRATEGY §5)
- 흐름: 로그인(이메일 입력→OTP 6자리 입력→검증) → `termsRequired`면 약관 동의 → `isNewUser`면 온보딩(아기 등록) → 홈.

### 1.2 baby (아기 프로필)
`Baby { id, userId, name, birthDate(yyyy-MM-dd), gender: male|female, birthWeightG, createdAt }`
- 웹은 MSA 경계상 서버에서 baby를 관리했으나, **iOS local-first에서는 baby도 로컬 SwiftData에 저장**(회원가입만 서버). 단 birthDate 기반 나이 계산·성장곡선 기준이 되는 핵심 엔티티.
- 온보딩 입력: 이름, 생년월일, 성별(male/female/unknown), 출생체중(kg 입력→g 저장, 0~15kg 검증).
- 출생체중 입력 시 **동시에 growth 레코드 1건 생성**(recordedAt=birthDate, weightG). → 대시보드/성장곡선 SSOT.
- 다중 아기 지원 여지 있으나 MVP는 활성 아기 1명(`activeBabyId`). 스키마는 babyId FK로 다중 대비.

### 1.3 feeding (수유)
`Feeding { id, babyId, feedingType, amountMl?, durationMinutes?, startedAt, endedAt?, memo?, createdAt }`
- `feedingType`: `formula | breast_left | breast_right | breast_both`
- 분유: amountMl 필수 관용. 모유: 좌/우/양쪽 + durationMinutes(수유 시간).
- 퀵세이브: 마지막 분유량 반복 저장 + 되돌리기(undo=삭제). 모유 좌/우/양쪽 원탭 저장.

### 1.4 sleep (수면)
`SleepRecord { id, babyId, startedAt, endedAt?, durationMinutes?, memo?, createdAt }`
- **진행중 세션(활성 타이머) 개념**: startedAt만 있고 endedAt 없으면 "자는 중". `StartSleepRequest`(시작), 종료 시 endedAt 채움 → durationMinutes 계산.
- 홈 상단 ActiveSessionBanner로 "수면 중 · 경과 1시간 20분" 표시, 탭하면 종료.

### 1.5 diaper (기저귀)
`DiaperRecord { id, babyId, diaperType, stoolColor?, stoolState?, recordedAt, memo?, createdAt }`
- `diaperType`: `pee | poo | both`
- `stoolColor`: yellow/green/brown/black/red/white (각 hex 존재 — UI 색점)
- `stoolState`: liquid/soft/normal/hard
- 소변은 원탭 저장. 대변은 색/상태 선택 시트(선택 안 해도 저장 가능).

### 1.6 play (놀이/터미타임)
`PlayRecord { id, babyId, playType, durationMinutes, startedAt, endedAt?, memo?, createdAt }`
- `playType`: `tummy_time(터미타임🤸) | free_play(자유놀이🎈) | sensory_play(감각놀이🎵)`
- durationMinutes 필수. 터미타임은 발달 대시보드에서 별도 집계됨.

### 1.7 growth (성장)
`GrowthRecord { id, babyId, recordedAt, weightG?, heightCm?, headCircumferenceCm?, memo?, createdAt }`
- 3개 지표 모두 nullable(측정한 것만 입력). 성장곡선(WHO 백분위) 차트의 데이터 소스.
- 출생체중은 온보딩에서 자동 1건 생성.

### 1.8 vaccination (예방접종)
`Vaccination { id, babyId, vaccineName, doseNumber, scheduledDate, administeredDate?, hospitalName?, memo?, isOverdue, daysUntil?, createdAt }`
- `isOverdue`, `daysUntil`는 웹에서 서버 계산 파생값 → **iOS는 로컬에서 scheduledDate vs 오늘로 계산**(저장 필드 아님, computed).
- 표준 접종 스케줄(BCG, B형간염 등)을 생년월일 기준으로 프리셋 생성. `MarkAdministeredRequest { administeredDate, hospitalName? }` = 접종 완료 처리.
- MVP: 표준 스케줄 프리셋 + 완료 체크. (프리셋 데이터는 Shared에 정적 JSON으로 번들.)

### 1.9 development (발달 정보) — **읽기 전용 콘텐츠**
- `DevelopmentStage`(연령 구간별 발달 이정표: grossMotor/fineMotor/cognition/language/social/selfCare, parentActions, warningSigns, feeding/sleep/playSummary, sources).
- `Milestone { days, label, emoji, category(celebration|checkup|developmental), description }`
- 웹은 서버 API였으나 **정적 콘텐츠**이므로 iOS는 번들 JSON(Shared/Resources)로 내장. 나이(ageDays)로 current/previous/next 스테이지 조회. 서버·네트워크 불필요.

### 1.10 recording / timeline (기록 허브 — 홈)
- 웹 Phase 9에서 `/record` 탭이 **홈으로 통합**됨. 홈이 기록의 중심.
- 구성요소:
  - `VoiceCommandHero` — 음성 기록(후순위, MVP 제외 가능)
  - `BigActionGrid` — 큰 버튼 그리드(수유/수면/기저귀/놀이 즉시 진입)
  - `QuickRepeatRow` — 마지막 기록 원탭 반복 + 되돌리기
  - `ActiveSessionBanner` — 진행중 수면 세션
  - `DayTimeline` / `TimelineScrollView` — 선택 날짜의 모든 기록을 시간순 피드(최신 강조)
  - `RecordEditSheet` / `RecordPopover` — 기록 상세 편집/삭제
- 날짜 네비게이션: 헤더에서 이전/오늘/다음 날짜 이동(`selectedDate`). 미래 날짜 불가.

### 1.11 dashboard (대시보드)
- `DailySummary { totalFeedingMl, feedingCount, totalSleepMinutes, sleepCount, diaperCount, poopCount, peeCount, totalPlayMinutes, tummyTimeMinutes, lastFeedingAt, lastDiaperAt, lastSleepAt }`
- `Prediction { lastFeedingAt, nextFeedingAt, feedingIntervalMinutes, feedingBasedOn, lastSleepEndedAt, nextSleepAt, awakeWindowMinutes, sleepBasedOn }`
  - "다음 수유 예상" = 최근 수유 간격 평균 기반. "다음 수면(깨어있는 시간창)" = 최근 awake window 기반.
- 카드: NextFeedingCard, FeedingAdequacyCard(수유 적정량 가이드라인 대비), DailySummaryCard, SleepChart, FeedingChart, TimelineView.
- **모든 값은 로컬 기록에서 계산**(파생). 저장하지 않는다.

### 1.12 trends (추세)
- 기간 토글(주/월 등 `TrendRangeToggle`), TrendChart, TrendInsightCard.
- `trendCalc` + `guidelines` 로 기간별 평균/추세를 계산하고 가이드라인 대비 인사이트 문구 생성. 역시 로컬 파생.

### 1.13 ai-* (AI 기능) — **후순위(서버 필요)**
- `ai-review`(오늘 리뷰): `DailyReview`(feeding/sleep/diaper/play Analysis, overallAssessment, alerts, recommendations, positives, considerations, concerns, criticalWarnings). 하루 기록을 서버 LLM이 분석.
- `ai-chat`(소아과 상담): `ChatConversation` + `ChatMessage`(role user|assistant), 스트리밍 응답.
- `ai-review` 의 `SavedInfo`(저장 정보): 상담 답변을 카테고리(feeding/sleep/development/health/general)로 저장.
- `youtube-summary`: 유튜브 육아 영상 요약.
- → **모두 서버(core-service AI) 의존. local-first MVP에서 제외**, 동기화 붙일 때 함께 활성화.

### 1.14 caregiver (공동양육자)
- 초대코드 생성(`InviteResponse { code, expiresAt }`) → 공유 → 상대가 redeem 로그인.
- `CaregiverMember { userId, role, createdAt }` 목록.
- **서버(공유 계정·실시간 동기화) 의존**. local-first MVP에서는 제외, 동기화 단계에서 활성화. 스키마는 babyId 공유 전제로 미리 설계(DATA_STRATEGY의 syncState가 다중 기기 병합의 토대).

---

## 2. iOS 네비게이션 구조

### 2.1 루트 분기 (AppRootView)
```
if accessToken == nil            → AuthFlow (로그인)
else if termsRequired            → TermsAgreementView
else if 활성 baby 없음(신규)     → OnboardingView (아기 등록)
else                             → MainTabView
```
- 세션 복원(Keychain 읽기)이 끝나기 전(hydrating) 스플래시 유지 — 웹의 `useAuthHydrated` 교훈: 복원 전 토큰 null 오판으로 로그인이 풀리면 안 됨.

### 2.2 MainTabView (하단 TabView, 5탭으로 재구성)
웹 하단탭은 6개(홈/대시보드/추세/AI/발달/설정)였으나 iOS 관용구에 맞춰 **5탭 + AI 세그먼트**로 정리:

| Tab | SF Symbol | 화면 | MVP |
|-----|-----------|------|-----|
| 홈(기록) | `house.fill` | 기록 허브 + 오늘 타임라인 | ✅ |
| 대시보드 | `chart.bar.fill` | 일일 요약·예측·차트 | ✅ |
| 추세 | `chart.line.uptrend.xyaxis` | 기간별 추세·인사이트 | ✅ |
| 발달 | `sparkles` | 연령별 발달·이정표(번들) | ✅ |
| 더보기 | `ellipsis.circle` | 설정·예방접종·성장·AI·공동양육자 | ✅(AI·공동양육 항목은 후순위 잠금) |

- "추세"와 "발달"을 한 탭으로 합칠지 여부는 구현 재량. 위 5탭이 기본안.
- 상단에는 웹 Header에 대응하는 **아기 아바타 + 이름/나이 + 날짜 네비게이터**를 홈/대시보드/추세에 공통 표시(`selectedDate` 바인딩).
- AI는 웹처럼 세그먼트(오늘 리뷰/상담/저장 정보/YT 요약)로 진입 — "더보기 > AI" 안에서 세그먼트 컨트롤.

### 2.3 화면 흐름 요약
- **기록(홈)**: BigActionGrid 탭 → 도메인별 입력 시트(모달) → 저장 → 타임라인 즉시 반영 + 되돌리기 스낵바.
- **진행중 세션**: 수면 시작 → 배너 표시 → 탭하여 종료.
- **타임라인 편집**: 항목 탭 → RecordEditSheet(수정/삭제).
- **대시보드/추세**: 읽기 전용, 날짜/기간 토글.
- **성장**: 리스트 + 성장곡선 차트 + 추가 시트.
- **예방접종**: 표준 스케줄 리스트 + 완료 체크 + 병원명/날짜.

---

## 3. MVP 범위 vs 후순위

### MVP (Phase 1~3, local-first)
1. auth(이메일 OTP 로그인 + 약관) — 서버.
2. baby 온보딩(로컬 저장).
3. feeding / sleep(활성세션) / diaper / play — 기록·타임라인·편집·삭제·퀵세이브.
4. dashboard(일일요약·예측) + trends — 로컬 파생 계산.
5. growth(입력·성장곡선).
6. vaccination(번들 스케줄 프리셋 + 완료 체크).
7. development(번들 정적 콘텐츠).

### 후순위 (Phase 4+, 서버 동기화 붙일 때)
- ai-review / ai-chat / ai-saved / youtube-summary (서버 LLM).
- caregiver(공동양육자 공유·실시간 동기화).
- 음성 기록(VoiceCommandHero).
- 서버 백업/동기화(DATA_STRATEGY §4 — 로컬 스키마 덕분에 "거의 공짜").

이 구분의 핵심: **MVP의 모든 기록은 로컬에서 완결**되므로 네트워크 없이도 100% 동작. 후순위 기능만 서버가 필요하고, 그때 동기화 계층을 추가하면 기존 로컬 데이터가 그대로 push된다.
