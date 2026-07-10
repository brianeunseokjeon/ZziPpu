# MIGRATION_PLAN — local-first → server-first 전환 실행 계획

> 짝 문서: `DATA_STRATEGY_SERVER_FIRST.md`(왜/무엇), 이 문서(어떻게/순서/검증).
> 대상 코드: `zzippu_ios/zzippu/`. 개발 에이전트는 이 문서만 보고 슬라이스 단위로 구현한다.
> 원칙: **Domain 프로토콜(async화) + Feature(await 도입)만 최소 조정, Data 구현체 교체가 본체.** Auth 슬라이스는 이미 서버 기반 → 손대지 않음.

---

## 0. 전환 요약 (한눈에)

| 레이어 | 조치 |
|---|---|
| Domain 엔티티 | sync 메타 3필드 제거(`updatedAt/syncState/deletedAt`), `SyncState` 삭제, `Baby.photoData`→`photoUrl` |
| Domain Repository 프로토콜 | 동기 `throws` → `async throws`, sync 훅 3종 제거, `softDelete`→`delete` |
| Domain UseCase | `async throws`로 조정 |
| Data/Persistence(SwiftData) | **전체 삭제** (Models/Mappers/SwiftData*Repository/SchemaV1) |
| Data/Network(신규) | `APIClient` + 도메인별 `Remote*DataSource`/`Remote*Repository`/DTO/Mapper |
| Feature ViewModel | 동기 호출 → `Task { await … }` + 낙관적 업데이트/롤백 |
| App | `AppContainer`가 Remote 리포지토리 주입, SwiftData `ModelContainer` 제거, `activeBabyId` dev-UUID 제거 → 로그인 후 `GET /babies`로 확정 |
| Auth 슬라이스 | **무변경** |

---

## 1. 삭제할 파일 (SwiftData 도메인 저장소)

```
Data/Repositories/SwiftDataFeedingRepository.swift      ← 삭제
Data/Repositories/SwiftDataBabyRepository.swift         ← 삭제
Data/Repositories/SwiftDataGrowthRepository.swift       ← 삭제
Data/Persistence/Models/FeedingModel.swift              ← 삭제
Data/Persistence/Models/BabyModel.swift                 ← 삭제
Data/Persistence/Models/GrowthModel.swift               ← 삭제
Data/Persistence/SchemaV1.swift                         ← 삭제 (ModelContainer 팩토리 포함)
Domain/Values/SyncState.swift                           ← 삭제
zzippu/Item.swift                                        ← 삭제 (템플릿 잔재, SwiftData Item)
```
Mappers(`Data/Persistence/Mappers/*`)는 **삭제 후 `Data/Network/Mappers/`로 재작성**(Model↔Entity → DTO↔Entity). 물리적으론 새 파일로 만드는 게 깔끔.

---

## 2. 변경할 파일 (유지하되 수정)

### 2.1 Domain 엔티티
- `Domain/Entities/Feeding.swift`: `updatedAt/syncState/deletedAt` 제거. `static new`도 해당 인자 제거.
- `Domain/Entities/Baby.swift`: 위 3필드 제거. `photoData: Data?` → `photoUrl: String?`. `Gender.unknown`은 유지(서버 `gender?`가 null/미선택 대응).
- `Domain/Entities/GrowthRecord.swift`: 위 3필드 제거.
- (Auth 관련 엔티티 `AuthSession/TermDoc`는 무변경.)

### 2.2 Domain Repository 프로토콜 (async화 + 훅 제거)
- `Domain/Repositories/FeedingRepository.swift`:
  ```swift
  protocol FeedingRepository {
      func create(_ feeding: Feeding) async throws -> Feeding
      func update(_ feeding: Feeding) async throws -> Feeding
      func delete(id: UUID, babyId: UUID) async throws     // 서버 경로에 babyId 필요
      func fetch(id: UUID, babyId: UUID) async throws -> Feeding?
      func list(babyId: UUID, on day: Date) async throws -> [Feeding]
      func lastFeeding(babyId: UUID) async throws -> Feeding?   // list→첫 요소로 구현
  }
  ```
  ⚠️ 서버 경로가 `/babies/{baby_id}/feedings/{feeding_id}`라 delete/fetch에 `babyId`가 필요 → 시그니처에 추가.
- `Domain/Repositories/BabyRepository.swift`:
  ```swift
  protocol BabyRepository {
      func create(_ baby: Baby) async throws -> Baby
      func update(_ baby: Baby) async throws -> Baby
      func fetch(id: UUID) async throws -> Baby?
      func fetchAll() async throws -> [Baby]            // GET /babies
      func activeBaby() async throws -> Baby?           // fetchAll().first (MVP)
      func joinByCode(_ code: String) async throws -> Baby   // 공유 합류(신규)
  }
  ```
  `softDelete` 제거(서버에 baby 삭제 EP 없음). sync 훅 제거.
- `Domain/Repositories/GrowthRepository.swift`: `series(babyId:) async throws`, `create/delete async throws`, 훅 제거.

### 2.3 Domain UseCase
- `Domain/UseCases/SaveFeedingUseCase.swift`: `func execute(_:) async throws -> Feeding`, `try await repository.create`. 검증 유지.
- `RestoreSessionUseCase.swift`: 무변경(동기 Keychain).

### 2.4 Feature ViewModel (동기→비동기 + 낙관적 업데이트)
- `Feature/Feeding/FeedingViewModel.swift`:
  - `loadFeedings`/`saveFeeding`/`deleteFeeding`/`undoLastSave` 내부를 `Task { @MainActor in … await … }`로 감싸거나 메서드를 `async`로. `@Observable` 프로퍼티(`feedings, isLoading, errorMessage`)는 그대로.
  - `saveFeeding`: (1) 낙관적으로 `feedings`에 임시 항목 삽입 + `isLoading` (2) `await saveUseCase.execute` (3) 성공 시 반환 엔티티로 교체·`loadFeedings` (4) 실패 시 임시 항목 롤백·`errorMessage`.
  - `deleteFeeding`: 낙관적 제거 후 `await repository.delete(id:babyId:)`, 실패 시 복원.
  - **View(`FeedingInputSheet`, 타임라인)는 원칙 무변경** — ViewModel의 public 프로퍼티/메서드 이름을 유지하면 됨. (메서드가 async가 되면 호출부에 `Task`/`await`가 필요할 수 있으니 View의 버튼 액션만 `Task {}`로 감싼다.)
- `Feature/Onboarding/OnboardingViewModel.swift`:
  - `save()` → `async`. `try await babyRepository.create(baby)` 후 반환된 서버 Baby의 `id`로 `AppContainer.activeBabyId` 설정(콜백). growth 자동생성도 `await`.
  - `Baby.new`에서 sync 인자 제거 반영.
- `Feature/Home/HomeView.swift`: activeBaby 조회가 있으면 async 대응.

### 2.5 App 레이어
- `App/AppContainer.swift`:
  - `ModelContext`/`ModelContainer` 의존 제거. `init()`에서 SwiftData 대신 `APIClient` 1개 생성 후 각 Remote 리포지토리에 주입.
    ```swift
    let api = APIClient(
        tokenProvider: { KeychainTokenStore().load() },
        onUnauthorized: { [weak self] in self?.handleUnauthorized() }
    )
    self.feedingRepository = RemoteFeedingRepository(api: api)
    self.babyRepository    = RemoteBabyRepository(api: api)
    self.growthRepository  = RemoteGrowthRepository(api: api)
    self.authRepository    = AuthRepositoryImpl(remote: AuthRemoteDataSource(), tokenStore: KeychainTokenStore())
    ```
  - `activeBabyId`의 하드코딩 dev-UUID 제거 → `Optional<UUID>`로 두고 로그인 후 `GET /babies`로 채움.
  - `handleUnauthorized()`: `authRepository.signOut()` + `sessionState.setSession(nil)`.
  - `static var preview`: SwiftData 시드 대신 **Mock 리포지토리**(메모리 배열) 주입으로 교체. (프리뷰가 네트워크 안 타게.)
- `App/AppRootView.swift` / `zzippuApp.swift`:
  - `ModelContainer` 주입 코드 제거.
  - `hydrateSession()`: Keychain 세션 복원 후 **`await babyRepository.fetchAll()`** 호출 → 결과 유무로 `activeBabyRegistered` 결정, 첫 아기 id를 `activeBabyId`에. (기존은 로컬 `activeBaby()` — 이게 essy1224 빈 화면의 직접 원인.)
- `App/SessionState.swift`: 무변경(라우팅 상태 그대로). `needsOnboarding`은 이제 서버 조회 결과 기반.

---

## 3. 신규 파일 (Data/Network)

```
Data/Network/APIClient.swift                 # 공용 HTTP(§DATA_STRATEGY 3.1)
Data/Network/APIError.swift                  # detail 파싱 + 상태코드
Data/Network/APIDateCodec.swift              # datetime/date 코덱(§3.2)
Data/Network/DTOs/BabyDTO.swift              # BabyResponse/Create/Update 대응
Data/Network/DTOs/FeedingDTO.swift
Data/Network/DTOs/GrowthDTO.swift
Data/Network/DataSources/RemoteBabyDataSource.swift
Data/Network/DataSources/RemoteFeedingDataSource.swift
Data/Network/DataSources/RemoteGrowthDataSource.swift
Data/Network/Mappers/BabyMapper.swift        # DTO↔Baby
Data/Network/Mappers/FeedingMapper.swift     # DTO↔Feeding
Data/Network/Mappers/GrowthMapper.swift
Data/Repositories/RemoteBabyRepository.swift    # BabyRepository 구현
Data/Repositories/RemoteFeedingRepository.swift # FeedingRepository 구현
Data/Repositories/RemoteGrowthRepository.swift
```
후속 도메인(sleep/diaper/play/vaccination/dashboard)은 같은 3점 세트(DTO/DataSource/Repository)를 추가하되, 해당 Domain 엔티티·프로토콜을 먼저 신설해야 함(현재 iOS엔 Feeding/Baby/Growth 엔티티만 존재).

---

## 4. Auth 슬라이스 — 무변경 (확인만)
`Data/Auth/*`, `Domain/Repositories/AuthRepository.swift`, `Feature/Auth/*`는 이미 서버 기반. 단 두 가지 연동:
- `KeychainTokenStore`를 `APIClient`의 `tokenProvider`로 재사용.
- `redeemCode`(공동양육자 stub)와 별개로, 아기 공유는 `BabyRepository.joinByCode`(caregiver `POST /caregivers/join`)로 구현. `AuthConfig.baseURL`은 `APIClient`가 공유.

---

## 5. Feeding 슬라이스 마이그레이션 — 단계별 (기준 슬라이스)

1. `Feeding` 엔티티에서 sync 3필드 제거 → 컴파일 에러 지점이 곧 수정 대상 목록.
2. `FeedingRepository` 프로토콜 async화(§2.2).
3. `FeedingDTO`(`FeedingResponse`/`Create`/`Update`) + `FeedingMapper`(DTO↔Entity) 작성.
4. `RemoteFeedingDataSource`(4개 EP: POST/GET?date/PATCH/DELETE) 작성.
5. `RemoteFeedingRepository` 작성(프로토콜 구현, DataSource+Mapper 조합, `lastFeeding`=`list().first`).
6. `SwiftDataFeedingRepository`/`FeedingModel`/구 `FeedingMapper` **삭제**.
7. `SaveFeedingUseCase` async화.
8. `FeedingViewModel` async + 낙관적 업데이트/롤백(§2.4).
9. `AppContainer`에서 `RemoteFeedingRepository` 주입.
- 검증: essy1224 로그인 → 기존 서버 수유기록이 타임라인에 뜸 / 신규 저장이 서버에 생성됨(웹에서도 보임).

---

## 6. 개발 순서 (수직 슬라이스)

| # | 슬라이스 | 산출 | 완료(검증) 기준 |
|---|---|---|---|
| **S1** | 공용 네트워크 기반 | `APIClient`, `APIError`, `APIDateCodec` | 임의 인증 GET 200 + 401 시 세션 무효화 동작 |
| **S2** | Baby 원격화 + 데이터 표시 | `RemoteBabyRepository` + `hydrateSession`가 `GET /babies` 사용 | **essy1224 로그인 시 서버 아기가 뜨고, 아기 있으면 온보딩 안 뜸** (빈 화면 문제 해결) |
| **S3** | Feeding 원격화 (기준 슬라이스) | §5 전체 | 서버 수유기록 조회·생성·수정·삭제가 iOS↔웹 양방향 반영 |
| **S4** | 낙관적 업데이트/재시도 마감 | ViewModel 낙관적+롤백, APIClient 백오프 | 비행기모드에서 저장 시 즉시 UI 반영→실패 토스트→재시도 성공 |
| **S5** | Growth 원격화 | Growth 3점세트 | 성장 시계열 서버 표시, 온보딩 출생체중이 서버 growth로 생성 |
| **S6** | 공유(caregiver) | `joinByCode` + 초대코드 UI | 배우자 코드 합류 후 같은 아기·기록 공유 확인 |
| **S7** | 나머지 도메인 | sleep/diaper/play/vaccination/dashboard 엔티티·프로토콜·Remote 3점세트 | 각 화면 서버 연동 |
| **S8(후속)** | 오프라인 캐시(옵션 B) | 아웃박스 큐 + 읽기 캐시 | 앱 재시작 후 미전송 쓰기 자동 재전송 |

S1→S2→S3가 최소 성공 경로. **S2 완료 시점에 이번 전환의 원래 목표(essy1224 빈 화면 해결)가 달성**된다.

---

## 7. ARCHITECTURE.md 갱신 diff (구체)

- **§1 레이어 표 · Data 행**: "SwiftData `@Model`(PersistenceModel) ↔ Domain 매핑. Keychain, (미래) 네트워크" → "**HTTP(`APIClient`/`URLSession`)로 zzippu-api 호출. DTO ↔ Domain 엔티티 매핑. Keychain(토큰).** 서버가 진실의 원천." 의존 목록에서 `SwiftData` 제거.
- **§2 폴더트리**: `Data/Persistence/{Models,Mappers,SchemaV1}` → `Data/Network/{APIClient, DTOs, DataSources, Mappers}`. `Data/Repositories`는 `Remote*Repository`로.
- **§3 상태관리(@Observable)**: 유지. 단 "`@Query`/`ModelContext`" 언급 삭제(SwiftData 미사용). 읽기 화면은 ViewModel이 Repository(async) 조회 결과를 `@Observable` 배열로 노출 — 그대로 유효.
- **§4 DI(AppContainer)**: 예시를 `SwiftDataFeedingRepository(context:)` → `RemoteFeedingRepository(api:)`로. `ModelContext` 주입 제거.
- **§5 결정요약**: "Sync 훅을 프로토콜에 선반영해 미래 비용 0" 항목을 "**서버가 진실의 원천. Repository는 async 프로토콜, 구현은 Remote(HTTP). 공유는 caregiver 코드.**"로 정정. "Repository 프로토콜=Domain, 구현=Data" 원칙은 유지.
- 레이어 의존 규칙, Feature가 프로토콜만 의존, Domain 순수성(단 이제 `async` 허용) 문구는 유지.

---

## 8. 리스크 / 주의

- **날짜 혼용**(datetime vs date): growth·baby·vaccination의 date 필드를 datetime 디코더로 파싱하면 실패 → `APIDateCodec`에서 DTO별로 분리(§DATA_STRATEGY 3.2). S1에서 반드시 테스트.
- **`age_days`/`age_months`**: 서버 파생값. iOS는 클라 계산 유지 → BabyDTO에서 받되 엔티티엔 안 넣어도 됨.
- **id 생성 주체 변경**: 기존엔 클라가 UUID 생성. 이제 create 시 **서버가 id/created_at 부여** → 낙관적 항목은 임시 id, 서버 응답으로 교체. `Baby.new`/`Feeding.new`의 클라 UUID는 낙관적 표시용으로만.
- **프리뷰**: 네트워크 제거 위해 `MockRepository`(메모리) 필수. `AppContainer.preview` 반드시 Mock으로.
- **DEV_MODE**: 서버 `DEV_MODE`면 토큰 없이 dev user로 응답. 실제 검증은 prod(`onrender.com`) + essy1224 토큰으로.
