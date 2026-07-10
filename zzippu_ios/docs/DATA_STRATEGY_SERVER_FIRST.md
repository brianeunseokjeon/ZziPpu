# DATA_STRATEGY (server-first) — 데이터 전략 ★최중요★

> **이 문서가 기존 `DATA_STRATEGY.md`(local-first)를 전면 대체한다.**
> local-first(SwiftData가 진실의 원천) 전략은 폐기한다. 아래 §0 참조.
> 레이어·DI 규칙은 `ARCHITECTURE.md`, 필드 근거는 `PRODUCT_SPEC.md`.

---

## 0. 왜 바뀌었나 (사용자 확정 결정)

- 원래 전략: SwiftData가 진실의 원천, 서버 동기화는 나중. (계정만 서버, 기록은 로컬)
- **확정된 변경**: 양육자 간 공유(부부가 같은 아기 데이터를 다중 기기에서 실시간 공유)가 이 서비스의 **핵심 가치**로 확정됨.
- 따라서 **서버(zzippu-api)가 진실의 원천(source of truth)** 이다. iOS는 웹 프론트와 동일하게 서버에 저장·조회한다.
- 구체 증상: 기존 계정 `essy1224`로 iOS 로그인하면 서버에 있던 아기·기록이 iOS엔 안 보이고 **빈 화면**이 뜬다(로컬만 보기 때문). server-first로 바꾸면 즉시 해결된다.

### 결론 3줄 요약
1. **SwiftData의 운명 → MVP에서 도메인 저장소로 폐기.** `FeedingModel`/`BabyModel`/`GrowthModel`, `SchemaV1`, `SwiftData*Repository` 3종, sync 메타 4필드(`updatedAt/syncState/deletedAt` + `SyncState`)를 **제거**한다. Data 레이어는 HTTP `Remote*Repository`로 교체. (오프라인 캐시는 옵션 B로 후속 — §5)
2. **클린아키텍처는 그대로.** Domain 엔티티/Repository 프로토콜/UseCase, Feature의 `@Observable` ViewModel/View, AppContainer DI는 유지. **바뀌는 것은 Repository 프로토콜의 동기→비동기 시그니처와 Data 구현체뿐**이다.
3. **오프라인 전략 → MVP는 "낙관적 업데이트 + 재시도 백오프", keep-warm은 이미 완료.** 로컬 큐 기반 완전 오프라인은 옵션 B(후속). 근거 §5.

---

## 1. 서버 API 계약 (zzippu-api — 실제 라우터에서 추출)

- **Base URL(prod)**: `https://zzippu-api.onrender.com`
- **인증**: `Authorization: Bearer <accessToken>` (Keychain의 토큰). 미인증/만료 → `401`.
- **JSON**: 전부 **snake_case**. iOS는 `JSONEncoder.keyEncodingStrategy = .convertToSnakeCase`, `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`로 자동 변환 (기존 `AuthConfig`와 동일 관례).
- **날짜/시간**: `started_at` 등은 ISO8601 datetime, `birth_date`/`recorded_at`(growth)/`scheduled_date` 등은 date(`YYYY-MM-DD`). → **디코더/인코더 dateStrategy를 커스텀**해야 함(§3.2).
- **에러 바디**: FastAPI `{ "detail": "..." }` 또는 검증오류 배열 `{ "detail": [{ "msg": ... }] }`.
- **소유/공유 모델**: 서버가 JWT의 `user_id`로 baby를 필터한다.
  - `GET /babies` → 그 유저가 소유(`get_by_user(user_id)`)한 아기 목록.
  - 공유는 **caregiver 초대코드**로 이뤄짐: 소유자가 `POST /babies/{baby_id}/caregivers/invite`로 코드 발급 → 배우자가 `POST /caregivers/join {code}`로 그 아기의 공동양육자가 됨. 이후 배우자의 `GET /babies`에도 그 아기가 나온다. **이게 부부 공유의 메커니즘.**

### 1.1 엔드포인트 전량 목록 (경로 prefix: `/api/v1`)

인증 헤더는 (별도 표기 없으면) 모든 도메인 엔드포인트에 필수.

#### Baby — `baby_router`
| 메서드 | 경로 | 요청 바디 | 응답 | 비고 |
|---|---|---|---|---|
| POST | `/babies` | `BabyCreateRequest` | `BabyResponse` (201) | 아기 등록. `user_id`는 서버가 JWT에서 채움(바디에 넣지 않음) |
| GET | `/babies` | — | `[BabyResponse]` | **로그인 유저의 아기 목록(소유+합류). 홈 진입 시 최초 호출** |
| GET | `/babies/{baby_id}` | — | `BabyResponse` | 404 가능 |
| PATCH | `/babies/{baby_id}` | `BabyUpdateRequest` | `BabyResponse` | 부분수정. `photo_url` 포함 |
| GET | `/babies/{baby_id}/export?format=json\|csv` | — | 파일 | MVP 미사용 |

- `BabyCreateRequest`: `name`(1~100), `birth_date`(date), `gender?`(str), `birth_weight_g?`(int>0)
- `BabyUpdateRequest`: 위 + `photo_url?` (전부 optional)
- `BabyResponse`: `id, user_id, name, birth_date, gender?, birth_weight_g?, age_days, age_months, created_at, photo_url?`
  - ⚠️ `age_days`/`age_months`는 **서버 계산 파생값**. iOS `Baby` 엔티티엔 없음 → 무시하거나 표시용 별도 필드로 흡수. (기존 iOS는 클라에서 나이 계산 → 계속 클라 계산해도 됨.)

#### Caregiver(공유) — `caregiver_router`
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `/babies/{baby_id}/caregivers/invite` | — | `InviteResponse {code, expires_at}` (201) |
| GET | `/babies/{baby_id}/caregivers` | — | `[CaregiverMemberResponse {user_id, role, created_at}]` |
| POST | `/caregivers/join` | `{code}` (4~12자) | `BabyResponse` — 합류한 아기 |

#### Feeding — `feeding_router` (prefix `/babies/{baby_id}/feedings`)
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `` | `FeedingCreateRequest` | `FeedingResponse` (201) |
| GET | `?date=YYYY-MM-DD` | — | `[FeedingResponse]` (기본값 오늘) |
| PATCH | `/{feeding_id}` | `FeedingUpdateRequest` | `FeedingResponse` |
| DELETE | `/{feeding_id}` | — | 204 |

- `FeedingCreateRequest/UpdateRequest`: `feeding_type`(enum), `started_at`(datetime), `ended_at?`, `amount_ml?`(>0), `duration_minutes?`(>0), `memo?`
- `FeedingResponse`: `id, baby_id, feeding_type, started_at, ended_at?, amount_ml?, duration_minutes?, memo?, created_at`
- ⚠️ **서버엔 soft-delete/updatedAt/syncState 없음.** DELETE는 물리삭제(204). iOS의 `deletedAt`/`syncState` 개념은 서버에 존재하지 않음 → 도메인에서 제거(§4).

#### Sleep — `sleep_router` (prefix `/babies/{baby_id}/sleeps`) — start/end 모델
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `` | `SleepStartRequest {started_at, memo?}` | `SleepResponse` (201) |
| PUT | `/{sleep_id}/end` | `SleepEndRequest {ended_at}` | `SleepResponse` |
| GET | `?date=YYYY-MM-DD` | — | `[SleepResponse]` |
| GET | `/active` | — | `SleepResponse \| null` (진행 중 수면) |
| DELETE | `/{sleep_id}` | — | 204 |

- `SleepResponse`: `id, baby_id, started_at, ended_at?, duration_minutes?, memo?, created_at`

#### Diaper — `diaper_router` (prefix `/babies/{baby_id}/diapers`)
| POST `` | `DiaperCreateRequest {recorded_at, diaper_type, stool_color?, stool_state?, memo?}` | `DiaperResponse` |
| GET `?date=` | — | `[DiaperResponse]` |
| DELETE `/{diaper_id}` | — | 204 |
- `DiaperResponse`: `id, baby_id, recorded_at, diaper_type, stool_color?, stool_state?, memo?, created_at`

#### Play — `play_router` (prefix `/babies/{baby_id}/plays`)
| POST `` | `PlayCreateRequest {play_type, started_at, ended_at?, duration_minutes?, memo?}` | `PlayResponse` |
| GET `?date=` | — | `[PlayResponse]` |
| DELETE `/{play_id}` | — | 204 |

#### Growth — `growth_router` (prefix `/babies/{baby_id}/growth`)
| POST `` | `CreateGrowthRequest {recorded_at(date), weight_g?, height_cm?, head_circumference_cm?, memo?}` | `GrowthResponse` |
| GET `` | — | `[GrowthResponse]` (날짜 필터 없음 — 전체 시계열) |
| DELETE `/{record_id}` | — | 204 |
- ⚠️ growth의 `recorded_at`은 **date**(datetime 아님).

#### Vaccination — `vaccination_router` (prefix `/babies/{baby_id}/vaccinations`)
| GET `` | — | `[VaccinationResponse]` |
| GET `/upcoming` | — | `[VaccinationResponse]` (30일 내) |
| POST `/{vaccination_id}/administer` | `{administered_date(date), hospital_name?}` | `VaccinationResponse` |
- `VaccinationResponse`: `id, baby_id, vaccine_name, dose_number, scheduled_date(date), administered_date?(date), hospital_name?, memo?, created_at, is_overdue(파생 bool), days_until(파생 int?)`

#### Dashboard — `dashboard_router` (prefix `/babies/{baby_id}/dashboard`)
| GET `/daily?date=` | — | `DailySummaryResponse` (feeding/sleep/diaper/play 집계 + last_* 시각) |
| GET `/predictions` | — | `PredictionResponse` (다음 수유/수면 예측) |
- 서버 집계이므로 iOS는 **읽기 전용**으로 그대로 표시.

#### Development(정적) — `development_router` (prefix `/development`, **인증 불필요**)
| GET `/stages` | — | `[DevelopmentStageResponse]` |
| GET `/stages/current?age_days=` | — | `CurrentStageBundleResponse` |
| GET `/milestones` | — | `[MilestoneResponse]` |

#### AI / YouTube — `ai_router`, `youtube_router`
- MVP iOS 범위 밖. 필요 시 동일 패턴으로 후속 추가. (엔드포인트 스키마는 각 라우터 참조)

---

## 2. 데이터 흐름 (essy1224 빈 화면 문제 해결의 핵심)

```
로그인(기존 Auth 흐름, 무변경)
  → AuthSession.accessToken(Keychain) + userId 확보
  → 홈 진입 시 BabyRepository.fetchAll() = GET /api/v1/babies  ← 서버가 JWT user_id로 필터
      · 결과 있음 → 첫 아기를 activeBaby로 설정 → 기록 화면 진입
      · 결과 없음 → 온보딩(BabyOnboardingView) → POST /babies
  → 기록 화면 진입 시 FeedingRepository.list(babyId, on: date) = GET /babies/{id}/feedings?date=…
```

- **핵심**: 온보딩 분기 기준이 "로컬 activeBaby 유무"에서 "**서버 `GET /babies` 결과 유무**"로 바뀐다. 이래야 essy1224처럼 서버엔 아기가 있는 계정이 iOS에서 온보딩으로 잘못 빠지지 않고, 기존 데이터가 그대로 뜬다.
- `AppContainer.activeBabyId`의 하드코딩된 dev UUID(`00000000-…-0001`)는 **제거**하고, 로그인 후 `GET /babies` 응답의 첫 아기 id로 설정. (다중 아기 선택 UI는 후속. MVP는 첫 아기.)

---

## 3. iOS 네트워크 레이어 설계 (Data)

기존 `Data/Auth`의 패턴(`AuthConfig`+`AuthRemoteDataSource`+Keychain)을 **도메인 전반으로 일반화**한다.

### 3.1 공용 `APIClient` (신규 — `Data/Network/APIClient.swift`)
`AuthConfig`를 확장/재사용한다. 책임:
- Base URL 결합(`AuthConfig.baseURL` 재사용 — 단일 서버라 URL 상수 공유).
- **Bearer 토큰 주입**: `KeychainTokenStore.load()`로 매 요청 `Authorization` 헤더 세팅.
- snake_case 인코더/디코더 (+ 날짜 전략, §3.2).
- 상태코드 검증 + FastAPI 에러 바디(`detail`) 파싱 → `APIError`.
- **401 처리**: 응답이 401이면 `SessionInvalidated` 신호를 발행(예: `AuthRepository.signOut()` 호출 + `SessionState.session = nil`). 웹의 `forceReauthRedirect`에 대응. → 사용자는 로그인 화면으로.

권장 시그니처(개발자 재량, 아래는 지침):
```swift
final class APIClient {
    init(baseURL: URL = AuthConfig.baseURL,
         tokenProvider: @escaping () -> String?,   // KeychainTokenStore.load
         onUnauthorized: @escaping () -> Void)      // 401 → 세션 무효화

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T
    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
    func postNoContent<B: Encodable>(_ path: String, body: B) async throws        // 204
    func patch<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
    func put<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
    func delete(_ path: String) async throws                                       // 204
}
```
- **재시도/백오프**: `post/patch/put/delete`(쓰기)에 한해 네트워크 오류·5xx·타임아웃 시 지수 백오프 재시도(예: 0.5s→1s→2s, 최대 3회). GET(읽기)은 재시도하되 실패 시 에러 노출. keep-warm 덕에 콜드스타트 타임아웃은 크게 줄었지만 **첫 요청 타임아웃은 넉넉히**(예: 30s) 잡는다.

### 3.2 날짜 인코딩/디코딩 (주의 — Auth엔 날짜 필드가 없어 미대비됨)
서버는 datetime과 date를 섞어 쓴다. `AuthConfig.decoder/encoder`엔 date 전략이 없으므로 **도메인용 별도 코덱**을 둔다:
- datetime 필드(`started_at, ended_at, recorded_at(diaper/play), created_at`): ISO8601(밀리초 유무 양쪽 허용하도록 커스텀 `DateFormatter`/`ISO8601DateFormatter` 조합).
- date 필드(`birth_date, recorded_at(growth), scheduled_date, administered_date`): `YYYY-MM-DD`. → DTO에서 `String`으로 받고 매퍼에서 변환하거나, 커스텀 `Decodable`.
- 안전책: **각 DTO를 서버 스키마 그대로(snake→camel 자동) 1:1 매핑**하고, date 계열은 DTO에서 `String`으로 받아 Mapper에서 `Date` 변환. 이러면 전역 dateStrategy 충돌을 피함.

### 3.3 도메인별 `RemoteXxxDataSource` + `RemoteXxxRepository`
각 도메인마다 2개 파일:
- `Data/Network/DataSources/RemoteFeedingDataSource.swift`: 순수 HTTP 호출 + DTO 반환. (서버 경로/스키마를 아는 유일한 곳)
- `Data/Repositories/RemoteFeedingRepository.swift`: `FeedingRepository`(Domain 프로토콜) 구현. DataSource 호출 + DTO↔Entity 매핑(Mapper).

DTO는 `Data/Network/DTOs/FeedingDTO.swift` 등에 배치. 기존 `Data/Persistence/Mappers/FeedingMapper.swift`의 "Model↔Entity" 매핑은 삭제되고, "**DTO↔Entity**" 매핑으로 대체된다(같은 파일 재활용 가능).

---

## 4. Domain 레이어 조정 (프로토콜 async화 — 유일한 Domain 변경)

**핵심 트레이드오프 지점.** 기존 Repository 프로토콜은 로컬 SwiftData 전제라 **동기 `throws`**다. HTTP는 본질적으로 비동기 → **`async throws`로 바꿔야 한다.** 이건 불가피하며, 클린아키텍처를 깨지 않는다(프로토콜 추상화는 그대로, 실행 모델만 async).

### 4.1 프로토콜 시그니처 변경 (Domain/Repositories)
```swift
// AS-IS (동기, 로컬)               →   TO-BE (비동기, 서버)
func create(_ f: Feeding) throws        → func create(_ f: Feeding) async throws -> Feeding
func update(_ f: Feeding) throws        → func update(_ f: Feeding) async throws -> Feeding
func softDelete(id: UUID) throws        → func delete(id: UUID) async throws           // 물리삭제로 개명
func fetch(id:) throws -> Feeding?      → func fetch(id:) async throws -> Feeding?
func list(babyId:on:) throws -> [..]    → func list(babyId:on:) async throws -> [Feeding]
func lastFeeding(babyId:) throws -> ..  → (유지하되 async; 서버엔 전용 EP 없음 → list 후 첫 요소로 구현)
```
- **반환값 추가**: create/update가 서버가 채운 `id/created_at`을 반영하려면 서버 응답 엔티티를 반환하는 게 낫다(웹도 그럼). ViewModel은 이 반환값으로 낙관적 항목을 확정 교체.
- **`softDelete` → `delete`**: 서버가 물리삭제(204)이므로 이름·의미 정정.

### 4.2 **삭제되는 sync 훅 3종** (프로토콜에서 제거)
`pendingSync / markSynced / applyRemote`는 local-first 동기화 전용 → **제거**. (옵션 B 캐시를 후속 도입하면 그때 별도 재설계.)

### 4.3 엔티티에서 sync 메타 제거
`Feeding`/`Baby`/`GrowthRecord`에서 `updatedAt`, `syncState`, `deletedAt` **삭제**. `SyncState`(Domain/Values) 파일도 삭제.
- 남기는 필드: 서버 스키마와 1:1 (`id, babyId, …도메인필드…, createdAt`).
- `Baby.userId`는 유지(서버 응답에 있음, 읽기용).
- `Baby.photoData: Data?` → 서버는 `photo_url: String?`이므로 **`photoUrl: String?`으로 교체**(이미지 업로드 EP는 별도, MVP는 URL 표시만).

### 4.4 UseCase
`SaveFeedingUseCase.execute`도 `async throws`로, 내부 `repository.create`를 `await`. 검증 로직(분유량>0)은 그대로. `RestoreSessionUseCase`는 Keychain 동기 복원이라 무변경.

---

## 5. 오프라인·신뢰성 전략 (결정: MVP = A′, 후속 = B)

세 선택지를 신생아앱 특성(밤중 수유, 가끔 오프라인) + 공유 우선 + keep-warm 완료 상황으로 평가:

| 옵션 | 내용 | 장점 | 단점 | 판정 |
|---|---|---|---|---|
| A 순수 서버 | SwiftData 완전 제거, 매번 서버 | 가장 단순, 공유 자연스러움, 기존 데이터 즉시 표시 | 네트워크 순단 시 쓰기 실패 노출 | MVP 기반 채택 |
| **A′ 서버 + 최소 방어** | A + **낙관적 업데이트 + 쓰기 재시도 백오프 + keep-warm** | 단순 유지하면서 밤중 순단 대부분 흡수 | 완전 오프라인(앱 종료 후 재전송)은 미보장 | **★ MVP 채택** |
| B 서버우선 + 로컬캐시 | read-through/write-through 로컬 큐, 오프라인 읽기·재전송 | 완전 오프라인 신뢰성 | 캐시 무효화·충돌·복잡도 큼 | **후속(Phase 2)** |

### 결정 근거
- **공유가 핵심 가치** → 진실의 원천은 무조건 서버. 로컬이 앞서면 부부 간 불일치가 생김. → A 계열.
- **keep-warm 완료** → 콜드스타트로 인한 첫 요청 지연이 크게 줄어, 순수 서버의 최대 약점이 완화됨.
- **신생아 부모의 밤중 기록** → 완전한 offline-first까지 필요하진 않지만(집 와이파이 환경이 대부분), **전송 실패로 기록이 사라지는 체감은 치명적** → 낙관적 업데이트로 즉시 UI 반영 + 백그라운드 재시도로 방어.
- 웹의 3계층 방어(낙관적 업데이트 + 재시도 백오프 + keep-warm)를 iOS로 **개념 그대로** 가져오되, 웹의 React Query mutation 영속 큐에 해당하는 "앱 재시작 후 재전송"은 **옵션 B로 미룬다**(복잡도 대비 이득이 MVP엔 과함).

### A′ 구체 동작(쓰기)
1. 사용자가 저장 → ViewModel이 **즉시 낙관적으로 로컬 상태(`feedings` 배열)에 추가**하고 스낵바(Undo) 표시. (SwiftData 아님, 메모리 상태)
2. `Task`로 `repository.create` 호출(서버 POST).
3. 성공 → 서버 반환 엔티티로 낙관적 항목 확정(id/created_at 교체).
4. 실패(재시도 소진) → 낙관적 항목 롤백 + 에러 토스트("저장 실패, 다시 시도"). 사용자가 재시도 버튼으로 재전송.
- 읽기: 실패 시 에러 상태 노출 + "다시 시도". (캐시 없음)

### Phase 2(옵션 B) 밑그림 — 지금은 구현 안 함
- 로컬에 **아웃박스 큐**(전송 대기 쓰기)만 SwiftData/파일로 보존 → 앱 재시작 후 재전송.
- 읽기 캐시(마지막 성공 응답)로 오프라인 열람.
- 이때 §4.2에서 지운 sync 훅과 유사한 개념이 **큐 전용으로** 부활하되, "진실의 원천은 서버"라는 전제는 불변.

---

## 6. 문서 갱신 계획

- **`DATA_STRATEGY.md`(구, local-first)**: 폐기. 파일 상단에 `> DEPRECATED — DATA_STRATEGY_SERVER_FIRST.md 로 대체됨` 한 줄만 남기거나 삭제. (MIGRATION_PLAN에서 실행)
- **이 문서(`DATA_STRATEGY_SERVER_FIRST.md`)**: 신규 정본.
- **`ARCHITECTURE.md`**: Data 레이어 서술만 갱신(§1 표의 Data 행, §2 폴더트리 `Persistence` → `Network`, §4 AppContainer 예시, §5 결정요약의 "Sync 훅 선반영" 항목 정정). 레이어 규칙·`@Observable` 상태관리·DI 골격은 유지. (MIGRATION_PLAN §7에 구체 diff)
- **`PRODUCT_SPEC.md`**: 기능 스펙은 유지(데이터 저장 위치 언급이 있으면 각주로 server-first 명시).
