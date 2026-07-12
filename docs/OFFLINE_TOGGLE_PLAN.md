# OFFLINE_TOGGLE_PLAN — 로컬 저장 계층을 "제거 가능·토글 가능"하게

> 목표: 로컬(SwiftData)·동기화 계층을 **한 곳의 스위치**로 켜고 끄고, 문제 시 **크래시 없이 자동 강등**하며, 필요하면 **파일 삭제 + 한 분기 제거**만으로 완전히 걷어낼 수 있게 한다.
> 원칙: Domain/Feature **무변경**. 토글·조립·폴백은 **App(Composition Root) 책임**. 결합도↓ 응집도↑.

현 사실(코드 확인됨):
- 오프라인 계층은 `Data/Persistence/*`, `Data/Sync/*`, `LocalFeedingRepository`, `SyncingFeedingRepository`에 격리.
- `RemoteFeedingRepository`(server-only) 이미 존재. 나머지 도메인은 전부 `Remote*`.
- Feature/Presentation/UI 어디도 `modelContainer`·`syncCoordinator`·`feedingSyncEngine`·`@Query`·`modelContext`를 **참조하지 않음**(grep 0건). 경계는 이미 깨끗함.
- 남은 결합점은 두 곳뿐: **`AppContainer.init`**(무조건 조립)과 **`zzippuApp`**(무조건 `.modelContainer` 배선 + scenePhase sync).

---

## 1. 킬 스위치 — Composition Root 팩토리

`AppContainer`가 **두 갈래로만** 갈라지도록 재구성한다. 오프라인 관련 심볼은 이 파일의 **한 분기 안에서만** 등장.

### 1.1 인프라를 옵셔널로 강등
현재 non-optional인 오프라인 프로퍼티를 옵셔널로 바꾼다(OFF/폴백 시 아예 nil):

```
// 오프라인 인프라 — OFF 또는 폴백 시 nil (SwiftData 의존 0)
let modelContainer: ModelContainer?       // ← 옵셔널화
let syncCoordinator: SyncCoordinator?
private let offline: OfflineInfra?         // 엔진·모니터·박스 묶음(아래)
var isOfflineActive: Bool { offline != nil }
```

동기화 엔진·NetworkMonitor·ActiveBabyBox는 하나의 값타입/클래스 `OfflineInfra`로 묶어 **오프라인일 때만 생성**. 이렇게 하면 AppContainer 본문에서 오프라인 심볼 노출이 최소화되고, 제거 시 이 묶음 참조만 지우면 된다.

### 1.2 리포지토리 조립을 팩토리로 분리
도메인별 "Local+Sync 만들기" vs "Remote 만들기"를 **한 함수의 분기**로:

```
init() {
    let api = APIClient(...)
    let mode = OfflineToggle.resolvedMode()   // §4: on/off 결정 + §2: 폴백 판정

    switch mode {
    case .offline(let container):             // 컨테이너 생성 성공한 경우에만 진입
        self.modelContainer = container
        let infra = OfflineInfra.make(api: api, container: container, babyIdProvider: …)
        self.offline = infra
        self.syncCoordinator = infra.coordinator
        self.feedingRepository = SyncingFeedingRepository(local: infra.localFeeding, engine: infra.engine)

    case .serverOnly:                          // OFF 또는 폴백
        self.modelContainer = nil
        self.offline = nil
        self.syncCoordinator = nil
        self.feedingRepository = RemoteFeedingRepository(api: api)
    }

    // ↓ 아래는 모드 무관 — 항상 Remote (S4 전까지)
    self.babyRepository = RemoteBabyRepository(api: api)
    …나머지 Remote…
}
```

**핵심**: `Local*`/`Syncing*`/`OfflineInfra`/`ModelContainer` 심볼이 등장하는 곳은 **`case .offline` 단 하나**. 이것이 "한 분기에서만 참조" 불변식이다.

### 1.3 zzippuApp 배선도 조건부
`.modelContainer(_:)`는 nil을 받을 수 없으므로 옵셔널로 감싼다. 없으면 SwiftData 환경 자체를 주입하지 않음(OFF 모드에서 SwiftData 런타임 완전 배제):

```
var body: some Scene {
    WindowGroup {
        rootView
            .modifier(OptionalModelContainer(container: appContainer.modelContainer))  // nil이면 no-op
            .task { appContainer.startNetworkMonitoring() }   // OFF면 내부에서 즉시 return
    }
    .onChange(of: scenePhase) { _, phase in
        if phase == .active { appContainer.triggerFeedingFullSync() }  // OFF면 no-op
    }
}
```

`startNetworkMonitoring()`·`triggerFeedingFullSync()`는 **이미 AppContainer의 메서드**이므로 내부에서 `offline?.…`로 옵셔널 체이닝 → OFF/폴백이면 자동 no-op. zzippuApp은 존재를 몰라도 됨(호출부 무변경, 시그니처 유지).

---

## 2. 자동 폴백 (안전밸브)

**규칙: ModelContainer 생성 실패 = 즉시 server-only로 강등. 크래시 금지.**

현재 `AppModelContainer.make()`는 실패 시 **인메모리로 force-try** → 이건 "로컬을 살리려다 오히려 위험"(force_try 잔존, 세션 한정 저장의 애매함). 이를 **throwing으로 전환**하고 폴백은 상위(토글 팩토리)에서 처리한다.

```
// AppModelContainer.make() → makeThrowing() : 실패를 삼키지 말고 throw
static func makeThrowing() throws -> ModelContainer { … try ModelContainer(…) }
```

```
// OfflineToggle.resolvedMode()
static func resolvedMode() -> Mode {
    guard userWantsOffline else { return .serverOnly }        // §4 토글 OFF
    do   { return .offline(try AppModelContainer.makeThrowing()) }
    catch {
        Log.error("ModelContainer init 실패 → server-only 강등", error)
        markOfflineDisabled(reason: .initFailure)             // 다음 부팅부터 OFF 고정(무한 재시도 방지)
        return .serverOnly
    }
}
```

### 폴백 흐름
```
앱 시작
  └ 토글 ON?
      ├ 아니오 ──────────────────────────► server-only (정상 최소 모드)
      └ 예 → ModelContainer 생성 시도
              ├ 성공 ─────────────────────► offline (Local+Sync)
              └ 실패(손상·마이그레이션 오류)
                    → 로그 + "offlineDisabled=true" 영속 기록
                    → server-only 강등 (앱은 계속 살아있음)
                    → (선택) 다음 실행에서 손상 스토어 파일 삭제 후 재활성 재시도
```

효과: 로컬이 깨져도 앱은 뜬다. `RemoteFeedingRepository`는 검증된 server-first 경로라 UX 저하는 "오프라인·pull-to-refresh 없음"뿐. **데이터 유실 아님**(서버가 진실원천).

---

## 3. 토글 방식 결정 (트레이드오프)

| 방식 | 재빌드 없이 끄기 | 사용자 노출 | 안전밸브 적합 | 결론 |
|---|---|---|---|---|
| 컴파일타임 플래그(`#if OFFLINE`) | ✕ | ✕ | 폴백 불가(런타임 상황 대응 못함) | 보조만 |
| 빌드 config(xcconfig) | ✕(별도 빌드) | ✕ | ✕ | 미채택 |
| **런타임 설정(AppStorage/UserDefaults)** | **○** | 선택 | **○ 폴백이 이 값을 쓸 수 있음** | **채택** |

### 채택: 런타임 토글(UserDefaults) — 단, **개발/디버그 전용**으로 시작
근거:
1. **폴백과 동일 메커니즘 재사용**: §2의 `markOfflineDisabled`가 결국 런타임 플래그를 끄는 것이므로, 토글도 같은 저장소를 쓰면 코드 하나로 "사용자 의도 OFF"와 "폴백 강등 OFF"를 통합 표현.
2. **재빌드 없이 현장 진단**: 로컬이 의심될 때 앱스토어 재심사 없이 끌 수 있어야 한다는 요구의 본질.
3. **일반 사용자에게는 숨김**: 오프라인/서버-전용은 데이터 정합·동기화 의미가 달라 일반 사용자가 토글하면 혼란·유실 오해 유발. → **디버그 메뉴(또는 개발 빌드 설정)에만 노출**. 정식 릴리스는 "기본 ON + 자동 폴백"으로 충분, 사용자 토글 미노출.
4. 결정 우선순위: **폴백 강등 플래그 > 사용자/디버그 토글 > 기본값(ON)**.

```
enum OfflineToggle {
    // 기본 ON. 폴백이 강등하면 이 값을 false로 덮어씀.
    static var userWantsOffline: Bool { get UserDefaults / set (디버그 메뉴 or 폴백) }
}
```

> 향후 오프라인이 충분히 안정되고 "오프라인 저장 사용" 설정을 **정식 노출**하고 싶어지면, 이 같은 플래그를 설정 화면 토글에 바인딩만 하면 됨(구조 변경 0). 지금은 노출하지 않는다.

---

## 4. 모드별 의미·동작 차이

| | **서버-전용(최소 모드)** = OFF/폴백 | **오프라인 모드** = ON |
|---|---|---|
| 진실원천 | 서버 | 로컬(우선) + 서버 동기화 |
| 네트워크 | **필수**(끊기면 조회·기록 실패) | 불필요(로컬 기록 → 복구 시 sync) |
| SwiftData | **미로드**(의존 0) | 로드 |
| SyncEngine/NetworkMonitor | 미생성 | 실행 |
| feeding 리포지토리 | `RemoteFeedingRepository` | `SyncingFeedingRepository` |
| 오프라인 상태 표시 UI | 숨김 | 표시(`syncCoordinator` 소비) |
| pull-to-refresh(수동 sync) | 없음/단순 재조회 | 있음 |
| 나머지 도메인 | Remote(동일) | Remote(S4 전까지 동일) |

**Feature/UI 규칙**: 오프라인 전용 UI(상태줄·pull-to-refresh)는 `appContainer.isOfflineActive`(또는 `syncCoordinator != nil`)로 **가드**. 값이 없으면 그 UI를 렌더하지 않음 → 두 모드가 같은 화면 코드를 공유하되, 오프라인 힌트만 조건부. Feature는 여전히 "로컬이 있는지" 모르고 **플래그 하나만** 본다.

---

## 5. 제거(삭제) 체크리스트 — 오프라인 계층 완전 걷어내기

아래만으로 Domain/Feature/다른 Data **무영향** 완전 삭제 완료:

1. [ ] `AppContainer.init`의 `case .offline` 분기 삭제 → `feedingRepository`를 무조건 `RemoteFeedingRepository(api:)`로.
2. [ ] `AppContainer`에서 `modelContainer`/`syncCoordinator`/`offline`/`isOfflineActive`/`ActiveBabyBox` 프로퍼티, `startNetworkMonitoring()`/`triggerFeedingFullSync()` 메서드 삭제(또는 no-op 유지).
3. [ ] `zzippuApp`에서 `OptionalModelContainer` modifier·`.task` sync·`.onChange scenePhase` sync 라인 삭제. `syncCoordinator` environment 주입 라인 삭제.
4. [ ] 폴더 삭제: `Data/Persistence/`, `Data/Sync/`.
5. [ ] 파일 삭제: `Data/Repositories/LocalFeedingRepository.swift`, `SyncingFeedingRepository.swift`, `App/OfflineToggle.swift`, `OfflineInfra.swift`.
6. [ ] 오프라인 상태 UI(있다면) 및 `isOfflineActive` 가드 제거.
7. [ ] `import SwiftData` 잔존 grep 확인 → 0건.
8. [ ] 빌드 → 남는 참조 없음 확인(컴파일러가 미삭제 참조를 잡아줌 = 경계가 좁다는 증거).

**보존 대상(삭제 아님)**: `Domain/Repositories/FeedingRepository.swift`(프로토콜), `RemoteFeedingRepository.swift`, 모든 Feature/ViewModel, 다른 `Remote*`.

> 삭제 리허설: 실제 삭제 없이 §4 토글을 OFF로 두면 런타임상 완전히 동일한 server-only 동작을 얻는다. 즉 **삭제 전 무위험 검증**이 가능.

---

## 6. S4 확장 정합 (도메인 추가 시 일괄 전환)

sleep/diaper/play/growth 로컬화 시에도 **같은 토글 하나로** 전부 전환되게:

- 도메인마다 `Local*Repository` + `Syncing*Repository` + `*SyncEngine`을 추가하되, **조립은 전부 `case .offline` 분기 안에서**.
- `OfflineInfra.make(...)`가 도메인별 엔진을 모아 반환(엔진 배열/딕셔너리). `startNetworkMonitoring`의 full-sync 트리거는 **엔진 목록을 순회**하도록 일반화 → 도메인 추가 시 배선 1줄.
- `SchemaV1.models`에 모델 추가(마이그레이션은 `SchemaMigrationPlan`으로 확장).
- 폴백은 도메인 무관하게 **컨테이너 단위**로 동작하므로 그대로 유효(하나 실패 = 전체 server-only, 부분 강등 없음 — 정합성 단순화 선택).
- `case .serverOnly`는 새 도메인도 `Remote*` 주입만 추가 → 두 분기 대칭 유지.

패턴 요약: **"도메인 리스트 × 모드 스위치"**. 새 도메인은 두 분기에 각 1줄씩, 토글/폴백/제거 경계는 불변.

---

## 7. 개발 착수 항목 (순서)

1. `AppModelContainer.make()` → `makeThrowing()` 전환(force-try·인메모리 폴백 제거, §2).
2. `OfflineInfra` 도입 — 엔진·coordinator·networkMonitor·babyBox 캡슐화(`make(api:container:babyIdProvider:)`).
3. `OfflineToggle` 도입 — `Mode`(`.offline(ModelContainer)`/`.serverOnly`), `resolvedMode()`, `userWantsOffline`, `markOfflineDisabled(reason:)`(UserDefaults).
4. `AppContainer` 리팩터: 인프라 프로퍼티 옵셔널화 + init을 §1.2 스위치 구조로. `start/​trigger` 메서드 옵셔널 체이닝 no-op화.
5. `zzippuApp`: `OptionalModelContainer` modifier, environment/sync 라인 조건부화.
6. 오프라인 전용 UI(있다면) `isOfflineActive` 가드.
7. (디버그 전용) 설정 디버그 메뉴에 오프라인 토글 노출 — 릴리스 빌드 제외.
8. 검증: 토글 OFF로 server-only 스모크 → ON 재확인 → ModelContainer 강제 실패 주입으로 폴백 스모크.

---

## 요약
- **토글**: 런타임 UserDefaults 플래그(디버그 노출), 기본 ON. 폴백·사용자·기본값 우선순위 통합. 컴파일타임 미채택(폴백 대응 불가).
- **폴백**: ModelContainer 생성 throw → 로그 + 플래그 강등 + server-only 진입. 크래시·유실 없음(서버가 진실원천).
- **경계**: 오프라인 심볼은 `AppContainer`의 `case .offline` 한 분기 + `zzippuApp` 조건부 배선에만. Feature/UI는 `isOfflineActive` 플래그 하나만 인지.
- **제거**: 한 분기 + 2폴더·4파일 삭제 → 완료. 토글 OFF로 무위험 삭제 리허설 가능.
