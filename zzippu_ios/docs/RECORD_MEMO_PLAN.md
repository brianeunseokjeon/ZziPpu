# 기록 메모 스펙 — 입력(편집 시트) + 타임라인 표시

> 상태: 스펙 확정(구현 대기). 작성: 프로덕트/디자인.
> **백엔드·데이터레이어 변경 0.** 순수 UI 작업. 모든 엔티티/DTO/스키마가 이미 `memo: String?` 지원 (확인됨).

---

## 0. 배경 / 확정 사실

- **엔티티**: `Feeding` / `SleepRecord` / `DiaperRecord` / `PlayRecord` 전부 `var memo: String?` 보유. `.new(...)` 팩토리 모두 `memo: String? = nil` 파라미터 지원. (검증: `zzippu/Domain/Entities/*.swift`)
- **DTO·백엔드**: Response/Create/Update, 백엔드 스키마·모델·라우터까지 배포 완료. → 손댈 것 없음.
- **입력 시트 VM**: `FeedingViewModel` / `DiaperViewModel` / `SleepViewModel` / `PlayViewModel` 에 이미 `var memo: String = ""` 상태 존재하고, 각 InputSheet 저장부에서 `memo: vm.memo.isEmpty ? nil : vm.memo` 로 실려 나감. **단, 화면에 memo 입력 UI가 없음** → 사용자가 값을 넣을 방법이 없다.
- **편집 시트** `RecordEditSheet.swift`: memo 상태·입력 UI 없음. `seed`(초기값 주입)와 `handleSave`(타입별 레코드 생성)에 memo 미반영.
- **타임라인**: `TimelineItem`(HomeViewModel)은 `label` / `time` 만 보유(memo 없음). `TimelineItemRow`(TimelineRow.swift)는 `[시간][dot][label …][chevron]` 렌더, memo 표시 없음.

---

## 1. 타임라인 표시 스펙 (핵심 — 확정값)

사용자 요구: "기록 옆에 연한 회색, 라벨보다 작게, 넘치면 …, 1줄 기본·2줄까지 OK, 없으면 미표시."

### 확정 결정

| 항목 | 결정값 | 근거 |
|---|---|---|
| **위치** | **라벨 아래 2번째 줄** (인라인 아님) | 라벨(`분유 70ml`)이 이미 `maxWidth:.infinity`로 우측 chevron까지 밀어 인라인 여백이 없음. 아래 줄이 정렬·가독성 안정. 웹의 서브텍스트 패턴과 일치. |
| **폰트** | `theme.typography.caption` = **12pt / regular** | 라벨은 `body` 14pt. caption 12pt가 "라벨보다 작지만 읽을 정도". `label`(12pt medium/트래킹)은 대문자성 태그용이라 부적합. `.footnote` 등 별도 토큰 신설 금지 — 기존 토큰만. |
| **색** | `theme.color.textTertiary` | "연한 회색". 시각·chevron과 동일 톤 → 정보 위계상 라벨보다 후순위임을 명확히. |
| **lineLimit** | **`.lineLimit(2)`** | 사용자: "1줄 기본, 2줄까지 OK, 넘치면 …". 짧은 메모는 1줄로 자연 표시되고 긴 메모만 2줄까지 확장 → `lineLimit(2)`가 요구와 정확히 일치(고정 2줄 아님, "최대 2줄"). |
| **자르기** | **`.truncationMode(.tail)`** | 2줄 넘치면 끝에 `…`. |
| **미표시** | memo가 `nil` 또는 공백(trim 후 빈 문자열)이면 **뷰 자체를 렌더하지 않음** | 행 높이·간격에 영향 0. `if let`가 아니라 trim 결과로 판정(빈 문자열 memo 방어). |
| **최신 행(highlighted)** | 톤 동일(`textTertiary` 유지). 굵기·색 변화 없음 | 최신 행에서도 메모는 보조 정보. 라벨만 semibold, memo는 그대로. |
| **정렬** | memo는 **라벨과 좌측 정렬 일치**(dot·시간 컬럼 아래로 들어가지 않음) | 라벨과 같은 `VStack(alignment:.leading)` 안에 배치 → 라벨 시작선과 memo 시작선 동일. |

### 레이아웃 변경 (TimelineRow.swift)

현재 라벨은 `HStack` 안에 단독 `Text`. → 라벨을 `VStack(alignment:.leading, spacing: 2)`로 감싸고 그 안에 라벨 + (조건부) memo 배치. `VStack`에 `.frame(maxWidth:.infinity, alignment:.leading)`를 옮겨 chevron 정렬 유지.

**전:**
```
HStack {
  Circle(dot)
  Text(label) .frame(maxWidth:.infinity,.leading)
  chevron?
}
```
**후:**
```
HStack(alignment: .top) {              // dot을 첫 줄에 맞추려면 .top + dot에 상단 여백 or .firstTextBaseline 검토
  Circle(dot)
  VStack(alignment:.leading, spacing: 2) {
    Text(label)                        // 기존 스타일 그대로 (body, isNewest면 semibold)
    if let memo = trimmedMemo {        // memo != nil && trim 후 비어있지 않을 때만
      Text(memo)
        .font(theme.typography.caption)
        .foregroundStyle(theme.color.textTertiary.color)
        .lineLimit(2)
        .truncationMode(.tail)
    }
  }
  .frame(maxWidth:.infinity, alignment:.leading)
  chevron?
}
```
- **dot 수직 정렬**: memo가 생기면 행이 2줄이 되므로 `HStack`을 `.top` 정렬로 바꾸고 dot을 첫 줄(라벨)에 맞춰 상단 정렬. 1줄일 때(메모 없음)도 어색하지 않아야 함 → dot에 미세 상단 패딩(예: `.padding(.top, 5)`)으로 라벨 baseline 근처에 맞추거나, dot을 라벨과 같은 첫 줄 baseline에 맞추는 방식 택1. 구현 시 라이트/다크 스냅샷으로 1줄·2줄 모두 확인.
- 기존 `.frame(minHeight: 29)`는 유지(1줄일 때 최소 높이). 2줄 memo는 자연 확장.

### VoiceOver (접근성)

- 행 전체 탭이 편집을 여는 구조이므로, memo가 있으면 행의 접근성 레이블에 포함되어야 함.
- 권고: `TimelineItemRow` 최상위에 `.accessibilityElement(children: .combine)` 유지되도록 하거나, 명시적으로 `.accessibilityLabel("\(time), \(label)" + (memo 있으면 ", 메모 \(memo)"))`. memo는 잘리지 않은 **전체 문자열**을 읽도록(시각 truncation과 무관).

---

## 2. 컴포넌트 API 변경 — `TimelineItemRow`

DS 컴포넌트에 파라미터 1개 추가(옵셔널, 기본 nil → 기존 호출부 무변경 호환).

```
public struct TimelineItemRow: View {
    public let time:      String
    public let label:     String
    public var memo:      String?      // ← 추가 (기본 nil)
    public let dotColor:  Color
    public var variant:   TimelineRowVariant
    public var onEdit:    (() -> Void)?

    public init(
        time: String,
        label: String,
        memo: String? = nil,           // ← 추가, 기본값으로 소스호환
        dotColor: Color,
        variant: TimelineRowVariant = .normal,
        onEdit: (() -> Void)? = nil
    ) { ... }
}
```
- 내부에서 `private var trimmedMemo: String? { let t = memo?.trimmingCharacters(in: .whitespacesAndNewlines); return (t?.isEmpty == false) ? t : nil }` 로 정규화.
- theme 토큰만 사용(caption / textTertiary) — 신규 토큰·하드코딩 색 금지.

---

## 3. 데이터 배선 — `TimelineItem` → 행

`TimelineItem`(HomeViewModel.swift)에 `memo` 추가하고 4개 `init(from:)`에서 원본 memo 주입.

```
struct TimelineItem: Identifiable {
    let id: UUID
    let time: Date
    let label: String
    let memo: String?          // ← 추가
    let domainKind: DomainKind

    init(from feeding: Feeding) { ...; self.memo = feeding.memo; ... }
    init(from sleep:   SleepRecord)  { ...; self.memo = sleep.memo;  ... }
    init(from diaper:  DiaperRecord) { ...; self.memo = diaper.memo; ... }
    init(from play:    PlayRecord)   { ...; self.memo = play.memo;   ... }
}
```

`HomeView.swift`(라인 542~548) 행 생성에 memo 전달:
```
TimelineItemRow(
    time:     item.time.timeString,
    label:    item.label,
    memo:     item.memo,        // ← 추가
    dotColor: theme.color.solid(for: item.domainKind).color,
    variant:  rowVariant,
    onEdit:   { editRecord = vm.editableRecord(for: item, on: day) }
)
```
그 외 HomeView 로직 변경 없음.

---

## 4. 메모 입력 UI — 편집 시트 `RecordEditSheet` (우선순위 1)

각 타입 필드(`typeFields`) + `timeFields` **아래**에 공통 "메모 (선택)" 필드 1개 배치. **분유·모유·소변·대변·수면·놀이 전 타입 공통**(사용자 요구: 소변/대변 포함).

### 상태 / seed / save

```
@State private var memo: String = ""
```
- **seed**(`seedState()`): 각 case에서 `memo = <원본>.memo ?? ""` 추가.
  - `.feeding(f)` → `memo = f.memo ?? ""`
  - `.sleep(s)`   → `memo = s.memo ?? ""`
  - `.diaper(d)`  → `memo = d.memo ?? ""`
  - `.play(p)`    → `memo = p.memo ?? ""`
- **저장**(`handleSave()`): 편집한 memo를 각 레코드에 주입.
  - `trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines); let memoOut = trimmed.isEmpty ? nil : trimmed`
  - **feeding**: `var u = f` 블록에 `u.memo = memoOut` 추가(현재 `d.memo`/`p.memo`처럼 원본 유지가 아니라 편집값 반영).
  - **diaper**: `DiaperRecord.new(..., memo: memoOut)` — 현재 `memo: d.memo`를 `memo: memoOut`로 교체.
  - **play**: `PlayRecord.new(..., memo: memoOut)` — 현재 `memo: p.memo`를 `memo: memoOut`로 교체.
  - **sleep**: ⚠️ 아래 5절 참고 — 현재 저장 경로가 memo를 아예 못 실음. 함께 처리.

### 입력 컴포넌트 — 멀티라인 방식

`DSTextField`는 단일 라인(`TextField`, height 고정 `input.height`)이라 개행 메모에 부적합. 두 안:

- **안 A (권장, 최소 변경):** `DSTextField`를 그대로 재사용해 **한 줄 입력**으로 제공. placeholder `"메모 (선택)"`, label `"메모"`.
  - 장점: 컴포넌트 신설 0, detent 0.62 높이 영향 최소(한 줄 = 기존 필드 1개 높이).
  - 개행은 막히지만, 타임라인 표시가 2줄 truncation이라 실사용상 짧은 메모가 대부분 → 요구 충족.
- **안 B (확장):** 시트 로컬에 경량 멀티라인 래퍼(`TextField(..., axis: .vertical).lineLimit(1...3)` 또는 `TextEditor` 배경/보더를 DSTextField 톤에 맞춘 인라인 뷰)를 둠. DS 정식 컴포넌트로 승격하지 않고 편집/입력 시트에서만 사용.
  - 장점: 개행·긴 메모 자연 입력. 단점: 높이 가변 → detent 영향.

**확정 권고: 안 A(한 줄 DSTextField)로 1차 출시.** 개행 요구가 실제로 나오면 안 B로 승격.

### detent / 스크롤 영향

- 필드 1개(한 줄) 추가 = `theme.space.md` 간격 + 필드 높이 ≈ 60~70pt 증가. 현재 `.fraction(0.62)` 유지 시 배변(색 5칩까지 뜨는 경우)에서 살짝 빡빡할 수 있음.
- `DSBottomSheet`가 이미 콘텐츠를 `ScrollView`로 감싸므로(파일 상단 주석: 여기서 GeometryReader/ScrollView 재사용 금지) memo 필드가 늘어나도 **스크롤로 흡수됨** → detent는 `.fraction(0.62)` 유지. 필요 시 `[.fraction(0.62), .large]` 조합(HomeView 라인 590)에서 사용자가 large로 끌어올릴 수 있어 안전.
- **주의**: RecordEditSheet 최상위는 순수 VStack(주석 경고). memo 필드도 그 VStack 안 `typeFields`/`timeFields`와 같은 계층에 넣고, **GeometryReader/추가 ScrollView 금지**.

---

## 5. ⚠️ 수면 저장 경로의 memo 손실 (반드시 함께 수정)

`SleepRecord`는 PATCH가 없어 **삭제→재생성** 전략(`HomeViewModel.replaceSleep(oldId:startedAt:endedAt:)`). 이 함수는 `SleepRecord.new(babyId:startedAt:)`로 새 레코드를 만들며 **memo를 전달하지 않음** → 수면 편집 시 memo가 사라진다.

- **필요 변경**: `replaceSleep` 시그니처에 `memo: String?` 추가하고 `SleepRecord.new(..., memo: memo)` 및 optimistic/placeholder에 반영. `RecordEditSheet`의 sleep case 저장에서 `vm.replaceSleep(oldId: s.id, startedAt: start, endedAt: end, memo: memoOut)` 호출.
- diaper/play는 이미 `.new(memo:)`를 받으므로 편집값만 넣으면 됨(4절). feeding은 `update`(PATCH)라 `u.memo` 반영으로 충분.
- 기존 `replaceSleep` 다른 호출부가 있으면 기본값 `memo: String? = nil`로 소스호환 유지.

---

## 6. 입력(생성) 시트 메모 — 우선순위 2 (선택)

VM에 `memo` 상태와 저장 배선은 이미 있음 → **UI만 추가하면 즉시 저장됨.**

- **최소 범위(권고):** `DiaperInputSheet` / `FeedingInputSheet` / `PlayInputSheet` / `SleepInputSheet` 각 폼 하단에 편집 시트와 동일한 "메모 (선택)" `DSTextField(text: $vm.memo)` 1개 추가.
- **확장 범위:** 안 B 멀티라인 적용, 프리셋(자주 쓰는 메모) 등 — 후속.
- 편집 시트(4절)와 입력 시트가 같은 UI 조각을 쓰도록 로컬 `memoField` 뷰를 각 시트에 두거나(중복 소폭 허용), 시트 공용 서브뷰로 뽑는 것 검토.

---

## 7. 엣지 케이스

| 케이스 | 처리 |
|---|---|
| 매우 긴 메모 | 타임라인 2줄 + `…`. 편집 시트는 한 줄 필드(안 A)면 스크롤/스크립트 축소 — TextField 기본 동작 허용. |
| 이모지 포함 | Text가 그대로 렌더. lineLimit/truncation 정상 동작. 폭 계산은 SwiftUI 위임. |
| 개행 포함(웹/타기기에서 생성된 memo) | 타임라인: `lineLimit(2)`가 개행도 줄로 계산 → 2줄 초과분 `…`. (안 A로는 신규 개행 입력 불가하나 표시는 정상.) |
| 빈 문자열 memo(`""` 또는 공백만) | 저장 시 `trimmed.isEmpty → nil`. 표시 시 `trimmedMemo → nil` → **미표시**. 행 높이 영향 0. |
| 편집 후 즉시 반영 | 저장이 낙관적 반영(`updateFeeding`/`replaceDiaper`/`replaceSleep`/`replacePlay`가 `recordsByDay` 즉시 mutate) → `timelineItems`가 새 memo로 재계산 → 행 즉시 갱신. 추가 작업 불필요. |
| 다크 모드 | `textTertiary`/`caption` 토큰이 다크 대응. 하드코딩 색 없음 → 자동. |

---

## 8. 적용 파일 & 태스크 (구현 순서)

| # | 파일 | 변경 |
|---|---|---|
| T1 | `Shared/DesignSystem/Components/Lists/TimelineRow.swift` | `memo: String?` 파라미터 추가, 라벨을 VStack으로 감싸 memo 2번째 줄 렌더(caption/textTertiary/lineLimit2/tail), dot 상단 정렬, `trimmedMemo` 정규화, VoiceOver 레이블에 memo 포함. |
| T2 | `Feature/Home/HomeViewModel.swift` | `TimelineItem`에 `memo` 필드 + 4개 `init(from:)`에 원본 memo 주입. |
| T3 | `Feature/Home/HomeView.swift` | 행 생성부(≈542)에 `memo: item.memo` 전달. |
| T4 | `Feature/Recording/RecordEditSheet.swift` | `@State memo`, seed에 원본 memo 로드, memo 입력 필드(안 A: DSTextField) 추가, handleSave 각 타입에 memoOut 주입. |
| T5 | `Feature/Home/HomeViewModel.swift` | `replaceSleep`에 `memo:` 파라미터 추가·전파(5절). RecordEditSheet sleep 저장에서 호출 갱신. |
| T6 (선택) | `Feature/{Diaper,Feeding,Play,Sleep}/*InputSheet.swift` | 각 폼에 memo 입력 필드 추가(VM·저장은 기배선). |

**MVP = T1~T5** (표시 + 편집 입력 + 수면 손실 방지). T6은 후속.

### 검증 체크리스트
- [ ] 메모 있는/없는 행 라이트·다크 스냅샷(1줄·2줄·초과 `…`).
- [ ] 빈/공백 memo → 미표시, 행 높이 동일.
- [ ] 분유·모유·소변·대변·수면·놀이 각각 편집→저장→타임라인 즉시 반영.
- [ ] 수면 편집 후 memo 유지(T5 회귀).
- [ ] VoiceOver로 행 포커스 시 memo 전문 낭독.
- [ ] 편집 시트 detent 0.62에서 배변 최대 필드 + memo 함께 스크롤 정상.
