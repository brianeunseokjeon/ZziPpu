# WEB ↔ iOS 시각 정합 감사 (WEB_NATIVE_AUDIT)

> 목적: "웹과 달라 보인다"는 반복 피드백의 **모든 시각적 불일치**를 화면별 1:1 대조로 전수 조사.
> 기준: **웹이 정답**(pixel-perfect 지향). iOS 관용(터치타깃 44 등)과 충돌 시 명시.
> 방법: 웹 컴포넌트(`frontend/src/...`)와 iOS 뷰(`zzippu_ios/zzippu/...`)를 나란히 읽고 색/폰트/간격/라운드/아이콘/레이아웃/상태를 구체 값으로 비교. **차이만** 기록.
> 표 형식: `웹 값` → `현재 iOS 값(추정)` → `수정 필요`.
>
> ⚠️ 중요 사실: 색·폰트·radius·space 원자값은 이미 `tokens.json` 하나로 웹·iOS 공용이라 **원자 토큰 자체는 대부분 일치**한다. 불일치는 (1) 컴포넌트가 토큰을 **다르게 적용**하거나, (2) **레이아웃/구성/문구가 아예 다르거나**, (3) tokens.json 스펙이 실제 웹과 어긋나 iOS가 스펙만 따른 경우에서 발생한다. 따라서 아래는 대부분 "적용/구성" 차이다.

---

## 0. 공통 근본원인 (한 번 고치면 여러 화면 해결)

| # | 근본원인 | 파급 화면 | 웹 값 | iOS 현재 | 수정 |
|---|---------|----------|-------|----------|------|
| **R1** | **카드 테두리** — 웹 카드는 라이트에서도 `border-gray-100`(가시 테두리)+`shadow-sm`. iOS `card.border`는 light=`transparent`(그림자만). | 대시보드 전 카드, 인증/온보딩 카드, 모든 `dsCard` | `border border-gray-100`(#F3F4F6) 항상 표시 | light 테두리 없음(투명) | tokens.json `component.card.border.light`을 `{semantic.color.border}`(#F3F4F6)로 변경 → `DSCard`가 light에서도 1px 테두리 렌더. 그림자는 유지. |
| **R2** | **인풋 스타일** — 웹 인풋은 **아웃라인형**(`bg-white` + `border-gray-200`). iOS `DSTextField`는 **채움형**(idle=surfaceSunken, 테두리 없음, focus 시만 링). | 로그인/온보딩 전 필드, 모든 `DSTextField` | `bg-white`, `border 1px #E5E7EB` 상시 표시 | 배경 surfaceSunken(#F3F4F6), idle 테두리 0 | tokens.json `component.input`: `bg`→`surface`(white), `border` 상시 표시(1px borderStrong)로 변경, `DSTextField`의 `borderColor`/`fieldBg`가 idle에도 흰 배경+회색 테두리 나오도록. focus는 primary 링. |
| **R3** | **본문 텍스트 색** — 웹 타임라인/카드 본문은 `text-gray-800`(#1F2937). iOS는 `textPrimary`(#111827, gray-900). | 타임라인 라벨, 카드 본문 다수 | #1F2937 (gray-800) | #111827 (gray-900) | 웹이 800을 본문에 쓰는 곳(타임라인 일반 행 라벨 등)은 iOS도 gray-800 상당으로. 미세하지만 "더 진해 보임"의 원인. 우선순위 낮음. |
| **R4** | **헤더/시트 타이틀 폰트 크기** — 웹은 아기이름 `text-base(16) bold`, 시트 타이틀 `text-lg(18) semibold`. iOS는 각각 `bodyStrong(14 semibold)`, `headline(16 semibold)`. | AppHeader, 모든 바텀시트 헤더 | 이름 16/bold, 시트 18/semibold | 이름 14/semibold, 시트 16/semibold | tokens.json `component.appHeader.titleTypography`→ 16pt bold(headline+bold 또는 신규), `bottomSheet` 헤더는 `title`(18) 사용. (직전 커밋에서 웹크기 14로 "축소"한 게 오히려 웹과 어긋남.) |
| **R5** | **바텀시트 X(닫기) 버튼 부재** — 웹 Dialog 헤더 우측에 X 버튼 + 하단 border. iOS는 X 없음(grabber만). | 모든 입력/편집 시트 | 우측 X(20pt, gray-500) + 헤더 하단 1px border | X 없음, 헤더 divider만 | iOS는 grabber 관용이 있으나 웹 정합 원하면 헤더 우측 `DSIconButton("xmark")` 추가. iOS 관용과 충돌 → 팀 결정 항목. |
| **R6** | **타임라인 도트 색** — 웹은 톤 낮은 팔레트(`blue-500/pink-400/cyan-400/yellow-500/purple-400/green-400`). iOS는 domain `.solid` 토큰. 일부 색조 어긋남. | 홈 타임라인 | 대변=`yellow-500`(#EAB308), 분유=`blue-500`(#3B82F6) | 대변=domainDiaperPoop(#EAB308 동일), 분유=domainFeedingFormula(#3B82F6 동일) — **대체로 일치**, 모유(web pink-400 #F472B6 = domainFeedingBreastLeft) OK | 확인 결과 색은 사실상 일치. 도트 **크기**만 확인(아래 화면3 참조). |

---

## 1. 홈 헤더 / 날짜 네비게이션

웹: `Header.tsx` · iOS: `AppHeader.swift`

| 축 | 웹 값 | iOS 현재(추정) | 수정 |
|----|-------|---------------|------|
| 아기 이름 폰트 | `text-base`(16) **bold**, gray-900 | `bodyStrong` = 14/semibold | 16pt/bold로 (R4) |
| 나이 텍스트 | `text-xs`(12) gray-**400**(#9CA3AF) | `caption` 12 gray-500(textSecondary #6B7280) | textTertiary(#9CA3AF)로 색만 변경 |
| 날짜 라벨 폰트 | `text-sm`(14) medium gray-700 | `captionStrong` = 12/semibold | 14pt medium(=body)로 키우기 |
| 날짜 라벨 최소폭 | `min-w-[110px]` | `minWidth: 52` | 110pt로 확대(오늘↔"M월 d일" 전환 시 폭 흔들림 방지) |
| chevron 아이콘 크기 | `w-4 h-4`(16) gray-500 | DSIconButton 기본 20pt | iconSize 16으로 |
| chevron 버튼 패딩 | `p-1.5`(6) 원형, active만 배경 | DSIconButton 44 프레임(투명) | 시각 동일(터치 44 관용 유지). 다만 아이콘 20→16 |
| 헤더 높이 | `h-14` = 56 | 56 | 일치 |
| 하단 테두리 | `border-gray-100` | divider(#F3F4F6=gray-100) | 일치 |
| "다음" 비활성 | `disabled:opacity-30` | opacity 0.3 | 일치 |
| 날짜 텍스트 내용 | 오늘도 "M월 d일" 표기(formatDate) | 오늘이면 "오늘" | **문구 불일치**: 웹은 오늘도 날짜를 그대로 노출. iOS는 "오늘"로 치환. 웹 정합하려면 오늘도 "M월 d일" 표기(또는 팀이 "오늘" 선호면 웹 수정). |

**차이 개수: 8**

---

## 2. 홈 6버튼 (BigActionGrid)

웹: `BigActionGrid.tsx` · iOS: `HomeView.swift`(BigActionButton) — *최근 수정됨, 잔차 확인*

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 이모지 크기 | `text-xl` = 20 | 20 | 일치 |
| 라벨 폰트 | `text-[11px]` semibold | 11/semibold | 일치 |
| gap(이모지↔라벨) | `gap-1` = 4 | space.xs(4) | 일치 |
| 세로 패딩 | `py-3` = 12 | stackGapMd(12) | 일치 |
| 그리드 gap | `gap-2` = 8 | space.sm(8) | 일치 |
| radius | `rounded-xl` = 12 | radius.control(12) | 일치 |
| 테두리 | 1px | 1px | 일치 |
| 눌림 | `active:scale-95` | scale 0.95 | 일치 |
| idle/active 팔레트 | bg{50}/border{100}/text{700} → bg{100}/border{300}/text{800} | quickButton 토큰 동일 매핑 | 일치 |
| **과거날짜 안내배너** | `rounded-xl bg-amber-50 border-amber-200 px-3 py-2 text-xs`, 텍스트 = "📅 **{날짜}**에 기록 중 · 버튼을 누르면 시각을 입력해요" | iOS PastFocusView 배너: `radius.control`, warningBg/warningFg, "오늘로" 버튼 **추가**됨 | 웹 배너엔 "오늘로" 버튼 없음(헤더 날짜네비로 복귀). iOS가 배너 안에 "오늘로"를 넣은 건 **추가 요소**. 웹 정합하려면 제거하거나 팀 결정. 색: amber-50/200/700 ≈ warningBg/warningFg — 확인 필요(warningFg=#B45309, amber-700=#B45309 일치). |

**결론: 버튼 자체는 정합 우수. 차이는 과거배너 "오늘로" 버튼(추가) 1건.**
**차이 개수: 1**

---

## 3. 홈 타임라인 (DayTimeline)

웹: `DayTimeline.tsx` + `TimelineScrollView.tsx` · iOS: `TimelineRow.swift`, `HomeView` 타임라인

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 시간 컬럼 폭 | `w-16` = 64 | `frame(width: 56)` | 64로 |
| 시간 폰트 | `text-[11px]` mono | mono(=12pt) | 웹 11 vs iOS 12 → mono 토큰 11pt로 낮추거나 iOS 유지(가독성). 미세. |
| 시간 색(일반) | gray-**400**(#9CA3AF, textTertiary) | textTertiary(#9CA3AF) | 일치 |
| 시간 색(최신) | blue-500 bold | statusInfoSolid(#3B82F6) bold | 일치(≈blue-500) |
| "최신" 뱃지 | `text-[9px]` blue-**400**(#60A5FA) medium | 9pt, **primary**(#60A5FA) | 일치 |
| 도트 크기(일반/최신) | 일반 `w-1.5`(6) / 최신 `w-2`(8) | 일반 6 / 최신 `timelineDotSizeIdle` | 최신이 `dotSizeIdle`(작은값)로 잘못 매핑된 듯 — **최신=8pt, 일반=6pt** 확인. 코드상 최신 분기에 `timelineDotSizeIdle`(=small) 사용 → 최신 도트가 안 커짐. **버그성 불일치**: 최신은 `timelineDotSize`(dotMd)를 써야 함. |
| 라벨 폰트 | `text-sm`(14) | body(14) | 일치 |
| 라벨 색(일반/최신) | 일반 gray-800 / 최신 gray-900 semibold | 일반·최신 모두 textPrimary(#111827=900) | 일반행을 gray-800로(R3) |
| 편집 아이콘 | 아웃라인 연필 `w-3.5`(14) gray-300, 배경없음 | DSIconButton pencil 14 tertiary(#9CA3AF) | 색: 웹 gray-300(#D1D5DB) vs iOS tertiary(#9CA3AF) — 웹이 더 연함. tertiary보다 연한 톤 필요(미세). |
| 최신 그룹 강조 배경 | `bg-blue-50/70`(#EFF6FF 70%) | primaryTint(#EFF6FF) opacity 0.7 | 일치 |
| 최신 좌측 바 | `border-l-[3px] border-blue-400` | 3px primary(#60A5FA) | 일치 |
| 행 min-height | `min-h-[1.8rem]`≈28.8 (그룹은 py-2.5) | `minHeight: 44` | iOS가 44(터치 관용). 웹은 촘촘. 시각적으로 **iOS가 더 성김** → 웹 정합하려면 밀도↑, 단 44 터치 관용과 충돌. 명시 후 팀 결정. |
| 날짜 섹션 헤더 | `text-xs`(12) semibold, 오늘=blue-500/기타=gray-500, 옆에 `text-[10px]` gray-400 날짜(YYYY-MM-DD) | captionStrong(12), 오늘=primary/기타=textSecondary, **부가 날짜(YYYY-MM-DD) 없음** | iOS 섹션 헤더에 어제/그제 옆 작은 `YYYY-MM-DD`(10pt gray-400) 추가 |
| "오늘로↑" 플로팅 버튼 | 있음(우하단, `text-[11px]` blue-500, 흰 배경 pill, shadow) | iOS TodayView엔 **없음** | 스크롤 시 "오늘로" 플로팅 버튼 추가(현재 iOS는 헤더 날짜네비로만 복귀) |
| 빈 상태 문구 | "이 날의 기록이 없어요" `text-xs` gray-300 | DSEmptyState 동일 문구 | 일치(색 tertiary vs gray-300 미세) |

**차이 개수: 8** (도트 최신크기 버그·시간폭·섹션 부가날짜·오늘로버튼이 눈에 띔)

---

## 4. 기록 입력 시트 (모달)

웹 홈 경로: `QuickOptionSheet.tsx`(Dialog) · iOS: `FeedingInputSheet.swift` 등 + `DSBottomSheet.swift`

> ⚠️ **가장 큰 구조적 불일치**. 웹 홈의 빠른기록은 **QuickOptionSheet**(슬라이더+프리셋+큰 숫자)인데 iOS는 **전체 폼형 InputSheet**(NumberStepper+DatePicker)로, UX 구성이 근본적으로 다르다.

### 4-A. 시트 컨테이너 / 헤더

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 상단 라운드 | `rounded-t-3xl` = 24 | presentationCornerRadius(sheet=24) | 일치 |
| 헤더 타이틀 | `text-lg`(18) semibold gray-900, **이모지 포함**("🍼 분유") | headline(16), 타이틀에 이모지 없음("모유 기록") | 18pt(R4) + 타이틀에 이모지 프리픽스 추가 |
| 헤더 X 버튼 | 우측 X 20pt gray-500 | 없음 | (R5) |
| 헤더 하단 border | `border-b border-gray-100` | divider | 일치(색) |
| 스크림 | `bg-black/40 backdrop-blur-sm` | 시스템 sheet 스크림 | iOS 시스템값(≈0.3~0.4). 근사. |
| 콘텐츠 패딩 | `p-5` = 20 | cardPadding 20 | 일치 |
| 콘텐츠 세로 리듬 | `space-y-5` = 20 | 섹션별 space.md(16) | 20으로 통일 |

### 4-B. 분유 입력 (formula)

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 큰 숫자 | 중앙 정렬 `text-3xl`(30) **bold blue-600**(#2563EB) + "ml" `text-sm` gray-500 | **없음** — DSNumberStepper의 title(18) 숫자만 | 웹처럼 큰 파란 숫자(30/bold/blue-600) 중앙 표시 추가 |
| 값 조절 | `−`/`+` **원형 40pt**(w-10 h-10 gray-100) + **슬라이더**(range, accent-blue) | DSNumberStepper: 사각 44pt ±버튼, 슬라이더 **없음** | 웹은 슬라이더 중심 UX. iOS엔 슬라이더 없음 → 큰 구조차. 최소한 −/+ 를 **원형**으로, 가능하면 Slider 추가 |
| 프리셋 | `[60,80,100,120,150,180]` **6개**, pill, 선택 시 `bg-blue-500 text-white border-blue-500`, 미선택 `bg-white border-gray-200 text-gray-600` | QuickChips `[100,120,150,180]` **4개**, 선택 시 primaryTint 배경/primary 텍스트(채움 아님) | 프리셋 6개로, 선택칩 스타일을 **파란 채움(blue-500/흰글자)**로(웹은 solid, iOS는 tint) |
| 배변 빠른추가 | 있음: "이 시각에 배변도 함께 기록" + 3버튼(소변/대변/둘다, `border-2` 파스텔) | **없음** | iOS FeedingInputSheet에 배변 빠른추가 블록 추가(웹 핵심 기능) |
| 시간 입력 | `TimeField`(라벨"기록 시간") | DatePicker(.date+.hourAndMinute, 라벨"시작 시각") | 웹은 시각만(time). iOS는 날짜+시각. 문구도 다름. |

### 4-C. 모유 (breast)

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 구성 | "어느 쪽으로 수유했나요?" + 좌/우/양쪽 3버튼(`border-2`, 선택=`bg-pink-50 border-pink-400 text-pink-700`, 이모지 ◀/▶/◀▶ `text-lg`) + 안내문 | 칩(DSChip) 가로 스크롤(FeedingType 전체), 이모지·측면선택 UI 없음 | 좌/우/양쪽 3버튼 그리드(핑크 파스텔 선택), 이모지 포함으로 재구성 |

### 4-D. 소변/대변/수면 확인 화면

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 구성 | 중앙 큰 이모지 `text-4xl` + 설명문 `text-sm gray-600` + 링크 안내 `text-xs gray-400` | iOS는 DiaperInputSheet/SleepInputSheet 폼(칩·스테퍼) | 웹 홈 빠른기록은 "확인만" 미니멀. iOS는 풀폼. UX 구성 상이 → 팀 결정(웹처럼 확인형 vs 현 풀폼 유지). |

### 4-E. 저장 버튼

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 스타일 | `w-full py-3.5 bg-blue-500 rounded-2xl(16) font-semibold text-sm`(14) | DSButton .primary .lg (높이 56, radiusLg 16, body 14 semibold) | radius 일치(16). 높이 근사. 색 primary(#60A5FA) vs 웹 blue-500(#3B82F6) → **버튼 배경색 차이**(아래 R 참조) |

> **추가 근본원인 R7 (프라이머리 버튼 색):** 웹 저장/CTA 버튼은 `bg-blue-500`(#3B82F6), iOS `primary`는 #60A5FA(blue-400). 웹 `button.tsx` default도 `bg-blue-400`이나, 시트/로그인 등 **주요 CTA는 blue-500**을 직접 씀. iOS 전 CTA가 한 톤 연함. → tokens `semantic.color.primary` light를 #3B82F6로 올리거나, CTA에 primaryPressed 계열 사용 검토. **파급: 모든 화면의 파란 버튼.**

**차이 개수(화면4): 15+** (구조적 최다)

---

## 5. 기록 편집 시트

웹: `RecordEditSheet.tsx` · iOS: `RecordEditSheet.swift` (HomeView에서 `dsBottomSheet`로 호출)

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 컨테이너 | Dialog(4-A와 동일) | DSBottomSheet | 4-A 항목 상속(헤더 18pt·X버튼·스크림) |
| 타이틀 | 이모지+한글("🍼 분유 수정" 등) | iOS `editSheetTitle`도 이모지 포함("🍼 분유 수정") | **일치**(문구·이모지 매핑 동일) |
| 삭제 동작 | 시트 내 삭제 버튼(destructive) | iOS는 contextMenu(길게눌러) 삭제 + confirmationDialog | **인터랙션 상이**: 웹은 시트 안 삭제, iOS는 롱프레스 메뉴. 웹 정합하려면 편집시트에 삭제 버튼 배치 |

*상세 필드 스타일은 4-A/4-B 근본원인에 수렴.*
**차이 개수: 2 (컨테이너 상속 + 삭제 인터랙션)**

---

## 6. 대시보드

웹: `dashboard/page.tsx`, `FeedingAdequacyCard`, `DailySummaryCard`, `FeedingChart`, `SleepChart`, `TimelineView` · iOS: `DashboardView`, `DashboardSummaryCards`, `MetricCard`, 등 — *최근 재설계됨*

> ⚠️ **의도적 대규모 재설계**. iOS는 링게이지·도넛·스파크라인·2열 MetricCard 그리드로 "건강앱化". 웹은 가로 막대 게이지 + 이모지 2×2 stat 타일 + 라인/바 차트. **동일 화면이 아님**. 아래는 "웹과 같게 하려면"의 차이. (팀이 iOS 재설계를 최종안으로 채택했다면 이 섹션은 웹을 iOS에 맞추는 역방향이 되어야 함 — **방향 확정 필요**.)

### 6-A. 상단 수유량 카드 (FeedingAdequacyCard)

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 게이지 형태 | **가로 막대**(`h-3` rounded-full, gray-100 트랙 + emerald-100 정상밴드 + 상태색 채움) | **원형 링게이지**(DSRingGauge 132pt) | 형태 자체 상이. 웹=가로 게이지. |
| 큰 숫자 | `text-4xl`(36) bold gray-900 + "ml" `text-base` gray-400 + "(분유 N회 기준)" `text-xs` | 링 중앙 display(36) + "ml" | 숫자 크기 일치(36). 위치(막대 위 vs 링 중앙) 상이 |
| 헤더 | 🍼 + "오늘의 수유량" `text-sm bold` + 우측 상태 pill | "오늘 수유량" captionStrong + 상태 pill(이모지 없음) | 문구 "오늘**의** 수유량", 🍼 아이콘, bold 14 맞추기 |
| 권장 문구 | "권장 **N~Nml**/일 · AAP 상한 960ml 적용" `text-xs` | "권장 N~Nml" body + "체중 기반 · AAP" caption | 문구·"/일"·상한 안내 정합 |
| 체중 입력행 | "현재 체중" + `WeightInline`(인라인 편집) 하단 border | **없음** | 대시보드 카드 내 체중 인라인 입력 추가(웹 핵심) |
| 면책 문구 | amber-50 박스 `text-[11px]` 긴 안내(AAP/HealthyChildren) + Info 아이콘 | **없음(카드엔)** | 면책 amber 박스 추가 |

### 6-B. 일일 요약 (DailySummaryCard)

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 구성 | **2×2 stat 타일**, 각 타일 `p-3 rounded-2xl` **파스텔 배경**(blue-50/purple-50/orange-50/green-50) + 이모지 `text-2xl` + 라벨 `text-xs` + 값 `text-lg bold` + sub `text-xs` | **2열 MetricCard 그리드**(SF Symbol + 스파크라인 bar/line + 도넛 + 탭시 상세 push) | 완전히 다른 컴포넌트. 웹=정적 이모지 타일(비클릭), iOS=차트+네비게이션 카드. 웹 정합하려면 이모지 파스텔 타일로 단순화(단 iOS의 상세 드릴다운 상실). |
| 이모지 | 🍼😴🧷🤸 | drop.fill/moon.fill/heart.fill/figure.play(SF Symbol) | 이모지 vs SF Symbol — **아이콘 종류 전면 상이** |
| 라벨 | 총 수유량/총 수면/배변/터미타임 | 수유/수면/기저귀/놀이 | **문구 상이**("배변"vs"기저귀", "터미타임"vs"놀이") |

### 6-C. 차트

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| FeedingChart/SleepChart | 별도 카드 차트(일자별 바/라인) | MetricCard 내 소형 스파크라인 + 상세뷰 | 웹은 대시보드 본문에 큰 차트 카드. iOS는 상세뷰로 이동. 구성 상이. |
| 다음 수유 예측 | 웹 `NextFeedingCard`(별도) | iOS `NextFeedingCard` 존재 | 존재는 일치, 스타일 대조는 별도 필요 |

**차이 개수(화면6): 12+ (근본적 재설계 — 방향 확정이 선결)**

---

## 7. 인증 (로그인 / OTP)

웹: `(auth)/login/page.tsx` · iOS: `LoginView.swift`, `OtpView.swift` (스크린샷 `/tmp/ds2_login.png` 확인)

### 7-A. 로그인

| 축 | 웹 값 | iOS 현재(스샷 확인) | 수정 |
|----|-------|---------------------|------|
| 로고 | **이모지 👶** `text-5xl` | **SF Symbol** `moon.stars.fill` 56pt primary | 웹은 이모지 👶. iOS는 달 아이콘 → **완전히 다른 로고**. 👶 이모지로 통일(또는 팀 브랜드 결정) |
| 앱 타이틀 | "찌뿌둥" `text-2xl`(24) bold gray-900 | `display`(36) bold | 24pt로 축소(display 36은 과대) |
| 서브 | "신생아 육아 기록" `text-sm`(14) gray-500 | callout(14) textSecondary | 일치 |
| **카드 컨테이너** | 폼 전체가 **흰 카드**(`rounded-2xl shadow-sm border-gray-100 p-6`) 안에 | **카드 없음** — 전체화면 중앙 배치 | 로그인 폼을 흰 카드로 감싸기(온보딩과 함께 R1 연동) |
| 이메일 라벨 | Mail 아이콘 + "이메일" `text-sm` medium gray-700 | "이메일" caption, 아이콘 없음 | 라벨에 Mail 아이콘 + 14pt medium |
| 이메일 인풋 | `h-12`(48) `text-lg`(18) `rounded-xl` border-gray-200 흰배경 | DSTextField(높이 44, input 16, 채움형) | 높이 48, 폰트 18, **아웃라인형**(R2) |
| CTA 버튼 | "인증번호 받기" `h-12`(48) `bg-blue-500` rounded-xl, disabled=`bg-gray-200 text-gray-400` | DSButton .lg(56, primary #60A5FA, radiusLg 16) | 텍스트 "인증**번호** 받기"(iOS "인증**코드**"), 높이 48, radius 12(xl), 색 blue-500(R7). disabled 회색 배경(현 iOS도 primaryDisabledBg 유사) |
| 헬퍼 문구 | "회원가입 없이 이메일 주소만으로 시작합니다." `text-xs` gray-400 | **없음** | 헬퍼 문구 추가 |
| **초대코드 진입** | "초대코드로 참여"(Ticket 아이콘) + invite step 전체 | **없음** | iOS에 초대코드 로그인 경로 부재 → 기능+화면 추가 필요 |
| 에러 표시 | `text-sm` red-500 `bg-red-50 border-red-100 rounded-lg px-3 py-2` | iOS는 `.alert`(시스템 팝업) | 인라인 에러 박스로(웹은 카드 내 인라인, iOS는 시스템 alert) |

### 7-B. OTP

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 로고 | (카드 상단, 별도 이모지 없음/이메일 표시) | envelope.badge.fill 48pt | 웹엔 OTP 아이콘 없음 |
| 타이틀 문구 | "인증번호 6자리" 라벨(별도 헤더 없음) | "인증코드 확인" title | 문구 "인증**번호**" 통일 |
| OTP 인풋 | `h-14`(56) `text-2xl`(24) center `tracking-[0.5em]` tabular, 6자리 | DSTextField 44, input 16, placeholder "000000" | 높이 56, 폰트 24, letter-spacing 넓게, 중앙정렬 |
| 유효시간 타이머 | 웹은 60초 재전송 카운트만("N초 후 재전송 가능") | iOS는 **5:00 유효시간 타이머**(clock, title, 만료 표시) — **웹에 없는 추가 UI** | iOS 유효시간 타이머 블록은 웹에 없음 → 제거하거나 팀 결정 |
| 재전송/변경 | "인증번호 재전송" 풀폭 버튼 + "이메일 변경"(code step 상단 인라인) | "코드 재전송 · 이메일 변경" 한 줄 | 배치·문구 상이 |
| 자동 제출 | 6자리 입력 시 자동 verify | iOS 수동(확인 버튼) | 6자리 자동 제출 추가 |

**차이 개수(화면7): 16+ (로고·카드·초대코드·인풋크기·문구 다수)**

---

## 8. 온보딩

웹: `(auth)/onboarding/page.tsx` · iOS: `BabyOnboardingView.swift`

| 축 | 웹 값 | iOS 현재 | 수정 |
|----|-------|---------|------|
| 로고 | 이모지 🍼 `text-5xl` | SF Symbol `figure.and.child.holdinghands` 48pt | 이모지 🍼로 |
| 타이틀 | "아기 정보를 알려주세요" `text-2xl`(24) bold | "아기 정보 등록" title(18) | 문구 통일 + 24pt bold |
| 서브 | "맞춤형 기록과 AI 피드백을 위해 필요해요." `text-sm` gray-500 | "기록을 시작하기 위해 아기 정보를 입력해 주세요." callout | 문구 통일 |
| **카드 컨테이너** | 폼이 흰 카드(`rounded-2xl shadow-sm border-gray-100 p-6`) | 카드 없음(전체화면 스크롤) | 카드로 감싸기(R1) |
| 이름 필드 | 라벨 "아기 이름" `text-sm` medium gray-700, `h-12`(48) 인풋 | "아이 이름 *" caption, DSTextField(44) | 문구 "**아기** 이름"(별표 없음), 높이 48, 라벨 14 medium |
| 생년월일 | `type="date"` `h-12` rounded-xl 인풋(네이티브 date) | DatePicker compact(surface 배경) | 웹은 인풋형. iOS compact picker — 근사하나 스타일 상이 |
| 출생체중 | 라벨 "출생 체중 (선택)"(선택=gray-400), number 인풋 `h-12` + "kg" | "출생체중 (선택)", DSTextField + "kg" | 라벨 문구 "출생 **체중**"(띄어쓰기), 높이 48 |
| 성별 | **3버튼 그리드**(`h-12` rounded-xl border, 선택=`bg-blue-50 border-blue-400 text-blue-700`), 이모지 👦👧· + "남아/여아/비공개" | **Segmented Picker**(.segmented) | 웹은 커스텀 3버튼(이모지+파란선택). iOS는 시스템 세그먼트 → **전면 상이**. 3버튼 그리드로 재구성 |
| 성별 문구 | 남아/여아/비공개 | Gender.displayName(확인 필요) | 문구 통일 |
| CTA | "시작하기" `h-12` `bg-blue-500` rounded-xl | DSButton .lg(56, primary) | 높이 48, radius 12, 색 blue-500(R7) |
| 에러 | 인라인 red 박스 | .alert | 인라인 박스로 |

**차이 개수(화면8): 11**

---

## 9. 공통 컴포넌트 (버튼/카드/인풋/칩/배지/토스트)

| 컴포넌트 | 웹 값 | iOS 현재 | 수정 |
|---------|-------|---------|------|
| **Button default** | `bg-blue-400`(#60A5FA) `h-11`(44) `rounded-xl`(12) `text-base`(16) medium; **lg=`bg`동일 `h-14`(56) `text-lg`(18) rounded-xl(12)** | .md 44/body14/radius12; **.lg 56/body14/radiusLg(16)** | ① lg radius: 웹 12(rounded-xl) vs iOS 16(controlLg) → **웹은 lg도 12**. iOS lg를 12로 낮추거나 팀결정. ② 폰트: 웹 md=16/lg=18, iOS 둘다 14 → 웹크기로 키우기. ③ 주요 CTA는 blue-500(R7) |
| Button outline | `border-gray-200 bg-white text-gray-900` | tertiary: 투명배경 borderStrong(#E5E7EB) 1.5px | 웹 배경 white(투명 아님), border 1px(iOS 1.5) |
| Button secondary | `bg-gray-100`(#F3F4F6) | surfaceSunken(#F3F4F6) | 일치 |
| **Card** | `rounded-2xl`(16) `border-gray-100` `bg-white` `shadow-sm` | radius16, light 테두리 투명 | **R1**(테두리 표시) |
| CardTitle | `text-lg`(18) semibold gray-900 | (사용처별) | 카드 제목 18pt 확인 |
| CardContent 패딩 | `px-5 pb-5`(20), header `p-5` | card.padding 20 | 일치 |
| **Input** | `h-11`(44) `rounded-xl`(12) `border-gray-200` `bg-white` `text-base`(16) placeholder gray-400 | 채움형 surfaceSunken | **R2** |
| **Chip 프리셋** | 선택=`bg-blue-500 text-white`(solid) 미선택=`bg-white border-gray-200 text-gray-600` | 선택=primaryTint 배경/primary 글자(연한 채움), 미선택 surfaceSunken | 웹 프리셋 선택은 **solid 파란 채움+흰 글자**. iOS는 연한 tint. → 프리셋(quick) 변형은 solid로 |
| Chip 높이 | 웹 프리셋 `py-1.5`(높이≈30) | 44(터치 관용) | iOS 44 유지(오탭 방지) — 명시. 시각적으로 iOS 칩이 더 큼. |
| Chip radius | `rounded-full` | pill | 일치 |
| **Toast** | 하단중앙, `px-4 py-3`(패딩 16/12) `rounded-xl`(12) `shadow-lg` `text-sm`(14) medium + border; success=`bg-green-50 border-green-200 text-green-700`, info=`bg-gray-800 text-white`, error=`bg-red-50 border-red-200 text-red-700`; X 닫기 아이콘 | ToastCenter(토큰: radius control12, padding 12, captionStrong 12) | ① 폰트 웹 14 vs iOS 12(captionStrong) → 14로. ② 패딩 웹 px-4(16)/py-3(12) vs iOS 12. ③ **variant 색 3종**(success 그린박스/info 다크/error 레드박스) — iOS variant 색 매핑 확인 필요. ④ X 닫기 아이콘 |
| statusPill | `px-2.5`(10) `py-1`(4) `rounded-full` `text-xs`(12) semibold | paddingX 12 / paddingY 6 / captionStrong | 웹 px-2.5(10)·py-1(4) vs iOS 12·6 → **iOS pill이 더 큼**. 웹값(10/4)으로 |
| Badge | `rounded-full` `px-2`(8) `text-[11px]`? | label(12) paddingX 8 | 근사(웹 라벨 크기 확인) |

**차이 개수(화면9): 12**

---

## 가장 큰 불일치 Top 10 (웹값 → 수정)

| 순위 | 항목 | 웹값 | iOS 수정 |
|------|------|------|---------|
| 1 | **로그인/온보딩 로고** | 이모지 👶 / 🍼 (text-5xl) | SF Symbol(moon.stars / figure) → **이모지로 교체** |
| 2 | **인증/온보딩 카드 부재** | 폼이 흰 카드(rounded-2xl border shadow) 안 | 전체화면 → **흰 카드로 감싸기** |
| 3 | **인풋 아웃라인 vs 채움** | `bg-white border-gray-200`(아웃라인) | 채움형(surfaceSunken) → **아웃라인 흰배경+회테두리**(R2) |
| 4 | **분유 입력 UX** | 큰 파란 숫자(30/blue-600)+슬라이더+6프리셋+배변빠른추가 | 스테퍼+4칩, 슬라이더·배변추가 없음 → **웹 구성으로 재현** |
| 5 | **프라이머리 CTA 색** | blue-500(#3B82F6) | primary #60A5FA(연함) → **blue-500로**(R7) |
| 6 | **초대코드 로그인 부재** | "초대코드로 참여" 경로 존재 | 없음 → **추가** |
| 7 | **카드 테두리 부재** | `border-gray-100` 상시 | light 투명 → **1px 테두리**(R1) |
| 8 | **온보딩 성별 선택** | 이모지 3버튼 그리드(파란선택) | 시스템 Segmented → **커스텀 3버튼** |
| 9 | **대시보드 구성 상이** | 가로 게이지+이모지 2×2 타일 | 링게이지+도넛+스파크 MetricCard → **방향 확정 후 정합** |
| 10 | **헤더/시트 타이틀 폰트** | 이름 16/bold, 시트 18/semibold | 14/16 → **키우기**(R4) |

---

## "웹과 동일" 개발 체크리스트 (하나씩 지우며 작업)

### 근본원인 (tokens.json / DS 컴포넌트 — 최우선, 다화면 파급)
- [ ] R1 `component.card.border.light` = border(#F3F4F6) → DSCard light 테두리 표시
- [ ] R2 `component.input` bg=white·border 상시 → DSTextField 아웃라인화
- [ ] R4 `component.appHeader.titleTypography`=16/bold, 시트 헤더=18/semibold
- [ ] R5 시트 헤더 X 버튼(팀 결정)
- [ ] R7 `semantic.color.primary` CTA=blue-500(#3B82F6) 검토
- [ ] Chip `quick` 변형 선택 스타일 solid(blue-500/흰글자)
- [ ] statusPill paddingX 10 / paddingY 4로 (현 12/6)
- [ ] Toast 폰트 14·패딩 16/12·variant 3색·X 아이콘
- [ ] Button lg radius 12(현 16)·폰트 md16/lg18(현 14)

### 화면1 헤더
- [ ] 이름 16/bold, 나이 gray-400, 날짜라벨 14/medium·min-w 110, chevron 16pt
- [ ] 오늘도 "M월 d일" 표기(문구 결정)

### 화면3 타임라인
- [ ] 최신 도트 8pt(현 dotSizeIdle 오매핑 수정), 일반 6pt
- [ ] 시간 컬럼 폭 64, 일반행 라벨 gray-800
- [ ] 섹션헤더 어제/그제 옆 YYYY-MM-DD(10pt gray-400)
- [ ] "오늘로↑" 플로팅 버튼 추가

### 화면4 입력시트 (구조)
- [ ] 시트 타이틀 이모지 프리픽스 + 18pt
- [ ] 분유: 큰 파란 숫자(30/blue-600) + 슬라이더 + 프리셋 6개(solid 선택) + 배변 빠른추가
- [ ] 모유: 좌/우/양쪽 3버튼(핑크 파스텔, 이모지)
- [ ] 저장버튼 blue-500

### 화면5 편집시트
- [ ] 시트 내 삭제 버튼(현 롱프레스 메뉴)

### 화면6 대시보드 (방향 확정 선결)
- [ ] 수유카드: 가로 막대 게이지 + 체중 인라인 + 면책 amber 박스
- [ ] 일일요약: 이모지 2×2 파스텔 타일(문구 "배변"/"터미타임")
- [ ] 아이콘 SF Symbol→이모지

### 화면7 로그인/OTP
- [ ] 👶 이모지 로고, 타이틀 24/bold, 흰 카드
- [ ] 이메일 라벨 Mail 아이콘, 인풋 48/18/아웃라인
- [ ] 헬퍼 문구, 초대코드 경로, 인라인 에러박스
- [ ] OTP: 인풋 56/24/자간, 6자리 자동제출, 유효시간 타이머 제거(결정)

### 화면8 온보딩
- [ ] 🍼 로고, 타이틀 24/bold, 흰 카드
- [ ] 성별 이모지 3버튼 그리드
- [ ] 인풋 높이 48, 라벨 14/medium, 인라인 에러

---

## 이미 일치(정합 양호)하는 부분
- **홈 6버튼(BigActionGrid)**: 이모지/라벨/패딩/radius/팔레트/눌림 모두 일치 (과거배너 "오늘로" 추가 1건 제외).
- **홈 타임라인 하이라이트**(최신 배경 blue-50/70, 좌측 3px 바), 도트 **색**, "최신" 뱃지 색·크기.
- **편집시트 타이틀 이모지 매핑**.
- 헤더 높이(56)·하단테두리, 그리드 gap, radius 원자값 다수.

---

## 방향 확정이 필요한 결정 항목 (웹↔iOS 상충)
1. **바텀시트 X 버튼**: iOS grabber 관용 vs 웹 X. (R5)
2. **터치타깃 44**: 타임라인 행 밀도, 칩 높이 — iOS 44 유지 시 웹보다 성김.
3. **대시보드**: iOS 재설계(링/도넛/스파크)를 최종안으로 볼지, 웹(가로게이지/이모지타일)에 맞출지. **범위 최대 항목.**
4. **OTP 유효시간 타이머**: iOS 추가 UI를 살릴지 제거할지.
5. **입력 alert vs 인라인 에러**: iOS 시스템 alert vs 웹 인라인 박스.

*(문서 끝. 웹 기준 pixel-perfect. 수정은 가능한 한 tokens.json / DS 컴포넌트 1곳 수정으로 다화면 환원.)*
