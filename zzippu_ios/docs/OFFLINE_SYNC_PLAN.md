# OFFLINE_SYNC_PLAN.md — 오프라인-퍼스트 + 서버 동기화 설계 ★핵심 결정★

> 이 문서는 `DATA_STRATEGY.md`(폐기·local-first)와 `DATA_STRATEGY_SERVER_FIRST.md`(현 정본·server-first)의 **후속**이다.
> 두 문서는 각각 "로컬만" 또는 "서버만"의 극단을 택했다. 이 문서는 그 긴장을 **로컬=작업사본 / 서버=동기화 허브** 모델로 화해시킨다.
> 레이어·DI는 `ARCHITECTURE.md`, 필드 근거는 `PRODUCT_SPEC.md`, 서버 API 계약은 `DATA_STRATEGY_SERVER_FIRST.md §1`을 그대로 참조(재기술 안 함).

---

## 0. 코드 실측 결론 (설계의 전제)

설계 전에 실제 코드를 검증했다. 결과가 곧 백엔드 변경 명세의 근거다.

| 점검 항목 | 실측 결과 | 근거 파일 | 동기화 영향 |
|---|---|---|---|
| 서버 레코드에 `updated_at` | **없음** | `infrastructure/persistence/models/feeding_model.py` 등 전 모델 (grep 결과 0건) | 증분 pull 불가 → **추가 필요** |
| 서버 soft-delete `deleted_at` | **없음**. DELETE는 물리삭제 | `feeding_repository_impl.py:89 delete()` → `session.delete()` | 삭제 전파(tombstone) 불가 → **추가 필요** |
| POST가 클라 id 수용 | **아니오**. 서버가 `uuid4()` 생성 | `application/use_cases/feeding/create_feeding.py:16 id=uuid4()` | 재시도 시 중복 생성 위험 → **upsert 필요** |
| 증분 조회 EP | **없음**. GET은 `?date=` 하루 필터뿐 | `feeding_router.py:60 get_feedings` | `since=` pull EP → **추가 필요** |
| iOS 도메인 프로토콜 | **이미 `async throws`** + `babyId` 파라미터 보유 | `Domain/Repositories/FeedingRepository.swift` | 동기화 엔진과 이미 호환. **프로토콜 무변경** ✅ |
| iOS 엔티티 id 생성 | **이미 클라 UUID 생성** (`Feeding.new()` → `UUID()`) | `Domain/Entities/Feeding.swift` | 클라 id를 서버 PK로 쓰면 재매핑 0. **엔티티 무변경** ✅ |
| iOS create 반환 | **서버 에코 엔티티 반환** | `RemoteFeedingRepository.swift:16` | 낙관적 확정 패턴 이미 존재 ✅ |
| baby 소유/공유 | `user_id` FK + caregiver join(초대코드) | `baby_model.py`, `DATA_STRATEGY_SERVER_FIRST.md §1` | 공유 메커니즘 그대로 재사용 |

**한 줄 요약**: iOS 상위 레이어(Domain 프로토콜·엔티티·Feature)는 **이미 동기화 친화적**이다. 클라가 UUID를 만들고, 프로토콜은 async고, create는 서버 엔티티를 돌려받는다. 남은 일은 (1) 그 UUID를 서버가 **존중**하게 만들고(백엔드 upsert), (2) 로컬 영속층(SwiftData)을 되살려 오프라인을 뚫고, (3) 그 둘 사이에 동기화 엔진을 끼우는 것뿐이다.

---

## 1. 소유권 모델 — 결정: **"로컬=기기 작업 사본(로컬 진실) / 서버=공유 동기화 허브(공유 진실)"**

### 1.1 세 후보 비교

| 모델 | 진실의 원천 | 오프라인 쓰기 | 공유 정확성 | 복잡도 | 현 코드와의 거리 |
|---|---|---|---|---|---|
| **A. server-first + 캐시** (현 정본) | 서버 | 낙관적(메모리)만, 앱 재시작 시 유실 | ★★★ 자연스러움 | 낮음 | 0 (현재) |
| **B. 완전 local-first + sync** (구 폐기본) | 로컬(SwiftData) | 완전 | ★☆ 로컬이 앞서면 부부 불일치 | 중 | 큼 |
| **C. 로컬=작업사본 / 서버=허브** (★채택) | **로컬이 UI 진실 · 서버가 공유 수렴점** | 완전 | ★★★ 서버로 수렴(LWW) | 중 | 중 |

### 1.2 왜 C인가 — 두 진실의 화해

문제의 본질은 "**오프라인은 로컬이 진실이어야 하고, 공유는 서버가 진실이어야 한다**"는 모순이다. C는 이를 **시간축으로 분리**해 화해시킨다.

- **읽기·쓰기 순간(로컬 진실)**: UI는 항상 SwiftData만 본다. 서버가 슬립/다운이어도 조회·작성이 즉시 완결된다. 이 순간 로컬이 진실이다.
- **수렴 순간(서버 진실)**: 서버가 살아나면 동기화 엔진이 로컬 변경을 push하고 서버 변경을 pull한다. 충돌은 **서버 시각 기준 LWW**로 결정론적으로 수렴한다. 이 지점에서 서버가 "여러 기기의 진실을 합의하는 허브"가 된다.
- 즉 서버는 "**항상 옳은 원천**"이 아니라 "**최종적으로 합의되는 허브**"다. 이 재정의가 오프라인 내성과 공유 정확성을 동시에 준다. (분산시스템 용어로 **causal+LWW 수렴**, offline-first 앱의 표준.)

### 1.3 A(현 정본) 대비 C의 트레이드오프

- **A의 결정적 약점**: 낙관적 업데이트가 메모리에만 있어 **전송 실패 후 앱 종료 = 기록 영구 유실**. 신생아 부모의 밤중 기록에서 이 유실은 치명적. 사용자 요구 "데이터 유실 0"과 정면 충돌.
- **C가 A에 더하는 것**: 로컬 영속(SwiftData) + 아웃박스(dirty 큐). 앱을 껐다 켜도 미전송분이 살아남아 재전송된다. 이것이 A′(현 정본이 "옵션 B, 후속"으로 미뤄둔 것)의 실체이며, 사용자 요구상 **더는 미룰 수 없다**.
- **비용**: 양방향 병합 로직(pull merge)과 백엔드 4가지 변경. 이 비용을 §7 마이그레이션 슬라이스로 통제한다.

> **결론**: server-first(A)를 **폐기하지 않고 확장**한다. 서버는 여전히 공유의 진실원천이지만, 로컬을 "일시적으로 앞서갈 수 있는 작업 사본"으로 승격시켜 오프라인을 뚫는다. 구 local-first(B)와 달리 **로컬은 절대 서버를 영구히 이기지 않는다** — LWW로 항상 서버에 수렴한다.

---

## 2. 로컬 영속화 — SwiftData 재도입 + sync 메타 복원

구 `DATA_STRATEGY.md §1`의 `@Model` 스키마와 4메타필드를 **거의 그대로 부활**시킨다. 그 문서가 이미 상세 설계했으므로 여기서는 **차이점과 재도입 결정만** 기술한다(토큰 절약).

### 2.1 sync 메타 4필드 (전 @Model 공통, 구 문서 §1.1 그대로)

| 필드 | 타입 | 역할 |
|---|---|---|
| `id` | `UUID @Attribute(.unique)` | 클라 생성 PK. 서버 PK와 동일(§4 upsert 전제) |
| `updatedAt` | `Date` | LWW 병합 기준 + push 후 **서버 시각으로 덮어씀**(§4.3 시계 오차) |
| `syncStateRaw` | `Int` | `localOnly(0)/dirty(1)/synced(2)` — push 대상 판별 |
| `deletedAt` | `Date?` | tombstone. 물리삭제 대신 soft-delete로 서버에 전파 |

- 도메인별 @Model 본문은 구 `DATA_STRATEGY.md §1.2`와 동일(Feeding/Sleep/Diaper/Play/Growth/Vaccination/Baby). **단 1건 수정**: `BabyModel.photoData: Data?` → **`photoUrl: String?`** (server-first 전환 때 서버가 `photo_url`로 확정됨, `baby_model.py` 확인).
- `SchemaV1: VersionedSchema`로 감싼다. server-first 전환 때 이 @Model들을 지웠으므로, 재도입은 **빈 스토어에서 새 SchemaV1 생성**이다 → 마이그레이션 부담 없음(§7-0).

### 2.2 Domain struct ↔ @Model Mapper

- **중요**: Domain 엔티티(`Feeding` 등)는 §0에서 확인했듯 **현재 sync 메타가 없다**(server-first가 제거). 두 선택지:
  - (a) 엔티티에 sync 메타 재노출 (구 문서 방식) — Feature가 메타를 보게 됨.
  - (b) **엔티티는 순수 유지, sync 메타는 @Model에만** (★채택) — Repository/동기화 엔진만 메타를 다룬다.
- **(b) 채택 근거**: Feature/ViewModel은 `syncState`를 알 필요가 없다(§6 상태표시는 전역 SyncCoordinator가 담당). 엔티티를 순수하게 두면 **Domain·Feature 무변경**이 지켜진다(핵심 원칙). Mapper가 create 시 `syncState=.localOnly, updatedAt=.now`를 주입하고, toEntity 시 메타를 떨군다.

```
Data/Persistence/
  Models/FeedingModel.swift ...        // @Model + 4메타
  Mappers/FeedingModelMapper.swift     // Feeding(struct) ↔ FeedingModel, 메타 주입/제거
  Store/AppModelContainer.swift        // ModelContainer(SchemaV1)
```

---

## 3. Repository 재구성 — Local-backed (Domain 프로토콜 무변경 증명)

### 3.1 핵심 전환: Remote를 "데이터소스"로 강등

현재: `RemoteFeedingRepository`가 프로토콜을 구현하고 HTTP를 직접 친다.
목표: **`LocalFeedingRepository`가 프로토콜을 구현**하고 SwiftData만 만진다. HTTP(`RemoteFeedingDataSource`)는 동기화 엔진 전용 데이터소스로 강등된다.

```
Domain/Repositories/FeedingRepository (프로토콜, async throws)   ← 무변경 ✅
        ▲ 구현
Data/Repositories/LocalFeedingRepository                        ← 신규(로컬 즉시 R/W)
        │ 읽기/쓰기: ModelContext만. 오프라인 OK.
Data/Sync/SyncEngine ── uses ──▶ RemoteFeedingDataSource(HTTP)  ← 기존 파일 재활용
                        └────▶ LocalFeedingRepository (병합 대상)
```

### 3.2 프로토콜 무변경 증명

현 `FeedingRepository` 프로토콜(§0 실측):
```swift
func create(_:) async throws -> Feeding
func update(_:) async throws -> Feeding
func delete(id:babyId:) async throws
func fetch(id:babyId:) async throws -> Feeding?
func list(babyId:on:) async throws -> [Feeding]
func lastFeeding(babyId:) async throws -> Feeding?
```
- 모든 시그니처가 로컬 구현으로 **그대로 만족 가능**하다. `async throws`는 SwiftData에서도 성립(actor 경계). `create`가 `Feeding`을 반환하는 것도 로컬이 곧바로 채워 반환하면 됨(서버 왕복 불필요 → **더 빨라짐**).
- `delete(id:babyId:)`는 로컬에서 **soft-delete**(deletedAt=now, dirty)로 구현. 프로토콜 의미("삭제")는 유지, 물리삭제→tombstone은 구현 세부.
- **결론**: Domain 프로토콜 0줄, Domain 엔티티 0줄, Feature/ViewModel 0줄 변경. 바뀌는 것은 **DI 조립(AppContainer)에서 `RemoteXxxRepository` → `LocalXxxRepository` 교체 1줄/도메인** + Data/Sync 신설뿐. (구 `DATA_STRATEGY.md §4`가 예언한 "거의 공짜"의 실현.)

### 3.3 LocalRepository 쓰기 규칙 (구 문서 §3 계승)

- `create`: insert, `syncState=.localOnly, updatedAt=.now`. 즉시 엔티티 반환.
- `update`: `updatedAt=.now`. 기존이 `.synced`면 `.dirty`로, `.localOnly`면 유지.
- `delete`: `deletedAt=.now, updatedAt=.now, syncState=.dirty`. (`.localOnly`였다면 물리삭제 가능 — 서버가 모르는 레코드이므로.)
- 모든 조회(`list/fetch`)는 **`deletedAt == nil` 필터 강제**(tombstone은 UI 비노출).

---

## 4. 동기화 엔진 (핵심) — `Data/Sync/SyncEngine`

Feature는 이 엔진의 존재를 모른다(경계 봉인). 엔진은 도메인별 `LocalRepository`(병합용 특수 메서드) + `RemoteDataSource`(HTTP)를 오케스트레이션한다.

### 4.1 병합 전용 훅 (LocalRepository에 추가, 프로토콜 아님 — 구체 타입에만)

구 문서 §3의 `pendingSync/markSynced/applyRemote`를 **Domain 프로토콜이 아니라 Data 구체 타입**에 둔다(Feature 오염 방지). 동기화 엔진만 이 확장 인터페이스를 안다.

```
protocol SyncableStore {              // Data 레이어 내부 프로토콜
  func pendingChanges(babyId:) -> [Record]        // syncState != synced (tombstone 포함)
  func markSynced(ids:, serverUpdatedAt:)         // dirty→synced, updatedAt=서버시각
  func applyRemote(_ remote: [Record])            // LWW 병합 (아래 4.4)
  var lastPulledAt: Date? { get set }             // 도메인별 pull 커서
}
```

### 4.2 Push (증분·멱등)

```
dirty = store.pendingChanges(babyId)              // localOnly + dirty + tombstone
ack   = remote.push(babyId, dirty)                // POST /sync/push  (클라 id 그대로!)
store.markSynced(ack.ids, ack.serverTime)
```
- **멱등성의 핵심**: 클라 UUID = 서버 PK. 서버가 **upsert**(id 있으면 update, 없으면 insert)하므로 재시도로 같은 레코드를 두 번 보내도 중복이 안 생긴다. (§0에서 확인한 "서버가 uuid4로 무시"를 **고쳐야** 성립 — §5.)
- **부분 실패**: push는 레코드 배열 → 서버가 `{accepted:[ids], rejected:[{id,reason}]}` 반환. accepted만 markSynced, rejected는 dirty 유지 후 다음 트리거에 재시도. 전부 멱등하므로 재시도 안전.
- **배치/페이지네이션**: 배치 크기 200/req. dirty가 많으면 청크 반복. (신생아 앱 일일 레코드 수십 개 수준 → 대개 1배치.)

### 4.3 Pull (증분·커서)

```
changes = remote.pull(babyId, since: store.lastPulledAt)   // GET /sync/pull?since=
store.applyRemote(changes)                                  // LWW
store.lastPulledAt = changes.serverTime                     // 커서 전진
```
- **첫 동기화(전량 pull)**: `lastPulledAt == nil`이면 `since` 생략 → 서버가 전체 반환. 이후는 증분.
- **삭제 전파**: pull 응답에 `deleted_at != nil` 레코드가 tombstone으로 포함 → 로컬도 soft-delete 적용. 이래서 별도 삭제 API가 필요 없다(구 문서 §4의 "삭제도 일반 레코드처럼").
- **시계 오차**: 커서·`updatedAt`은 **전부 서버 시각**. push ack이 돌려준 `server_updated_at`을 로컬 `updatedAt`에 덮어써, 로컬 기기 시계 오차가 LWW 비교를 오염시키지 않게 한다. (기기 A가 미래 시각으로 setting해도 서버가 재타임스탬프하므로 안전.)

### 4.4 충돌 해결 — 레코드 단위 LWW (기본) + tombstone 우선

- **규칙**: 같은 `id`에 대해 로컬본 vs 서버본 → `updatedAt`(서버 시각)이 큰 쪽이 이긴다. 로컬이 dirty인데 서버가 더 최신이면 서버로 덮되, 로컬이 아직 push 안 한 순수 로컬 변경이면 push가 이긴다(push→pull 순서 보장, 4.6).
- **삭제 우선(delete-wins)**: 한쪽이 tombstone이고 `deletedAt`이 상대 `updatedAt`보다 크면 삭제가 이긴다. (부모 A가 지운 걸 부모 B의 오래된 수정이 되살리지 않게.) 동률이면 삭제 우선(보수적).
- **필드 단위 병합이 필요한가?** 검토 결과 **불필요**. 신생아 기록은 단일 사건(수유 1회, 기저귀 1회)이라 두 부모가 **같은 레코드의 서로 다른 필드**를 동시 편집할 개연성이 극히 낮다. 대개 서로 **다른 레코드**를 추가한다(→ 충돌 자체가 없음, 둘 다 살아남음). 유일한 실질 충돌은 "같은 진행중 수면 세션을 둘이 종료"인데, 이건 레코드 단위 LWW로 늦게 종료한 값이 이기면 충분. **레코드 단위 LWW로 충분**하다고 결론.
- **손실 최소화 안전장치**: LWW로 진 로컬 변경이 dirty였다면, 덮어쓰기 전 값을 **로컬 감사로그(선택)**에 남겨 "다른 기기가 덮어씀" 안내 가능(§6, MVP 밖).

### 4.5 트리거

| 트리거 | 동작 | 비고 |
|---|---|---|
| 앱 포그라운드 복귀 | full sync(push+pull) | 밤중 재개 시 최신화 |
| 네트워크 복구(`NWPathMonitor`) | full sync | 오프라인→온라인 전환 |
| 로컬 변경 후(디바운스 2~3s) | push only | 연속 입력 합침 |
| 당겨서 새로고침 | pull only | 사용자 명시 |
| 폴링(포그라운드 중 30~60s) | pull only | 공동양육 준실시간(§6) |
- **keep-warm과의 관계**: keep-warm(별도 완료)은 콜드스타트 지연을 줄여 sync **성공률·체감속도**를 높인다. 하지만 이 설계는 keep-warm에 **의존하지 않는다** — 서버가 죽어도 로컬로 완결되고, 살아나면 트리거가 수렴시킨다. keep-warm은 최적화, 오프라인 내성은 이 엔진이 보장.

### 4.6 동시성·순서·재시도

- **순서**: 한 sync 사이클은 항상 **push → pull**. 내 dirty를 먼저 서버에 반영해야, 곧이은 pull이 내 변경을 서버 확정본으로 되받아 커서가 일관된다. (pull 먼저면 내 dirty가 서버엔 없어 커서만 앞서고 다음 push가 꼬임.)
- **직렬화**: SyncEngine은 `actor`. 동시 트리거가 겹쳐도 사이클이 겹치지 않게 in-flight 플래그로 병합(진행 중이면 "dirty 있음" 표시만 남기고 끝나면 재실행).
- **재시도/멱등**: 모든 push는 upsert라 멱등 → 네트워크 오류·5xx·타임아웃 시 지수 백오프(0.5→1→2→4s, 최대 4회) 후 dirty 유지. 다음 트리거가 다시 집는다. **어떤 실패도 유실로 이어지지 않음**(dirty가 SwiftData에 영속).

---

## 5. 백엔드 변경 명세 (최소 변경안)

§0 실측 기준, 동기화에 **꼭 필요한 것만**. 도메인 8종(feeding/sleep/diaper/play/growth/vaccination/baby/…)에 공통 적용.

### 5.1 스키마: 전 레코드 모델에 2컬럼 추가

```
# 각 *_model.py 에 추가 (feeding_model.py 예시)
updated_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False, index=True)  # LWW+커서
deleted_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)         # tombstone
```
- **마이그레이션(`_migrate` 패턴)**: 기존 행은 `updated_at = created_at`으로 백필, `deleted_at = NULL`. Alembic(또는 현 프로젝트의 마이그레이션 관례) 1개 revision.
- `updated_at` 인덱스는 `since` 필터 성능용(baby_id + updated_at 복합 권장).

### 5.2 POST/PATCH: 클라 id 수용 + upsert (멱등성의 핵심)

- `CreateFeedingDTO`에 `id: UUID | None = None` 추가. `create_feeding.py`에서 `id = dto.id or uuid4()`.
- save를 **upsert**로: 같은 id 존재 시 update, 없으면 insert. (SQLAlchemy `merge` 또는 `INSERT ... ON CONFLICT(id) DO UPDATE`.)
- update/create 모두 `updated_at = now(utc)`로 서버가 재타임스탬프(§4.3). 응답에 `updated_at` 포함.
- **소유권 검증**: upsert 시에도 기존처럼 JWT `user_id`가 해당 baby의 소유자/합류자인지 확인(권한 우회 방지).

### 5.3 DELETE: soft-delete로 전환

- `feeding_repository_impl.py delete()`: `session.delete()` → `model.deleted_at = now; model.updated_at = now`.
- 기존 조회(`get_by_baby_and_date` 등)에 `deleted_at IS NULL` 필터 추가(사용자 화면엔 tombstone 비노출).

### 5.4 증분 pull 엔드포인트 (2안 중 택1)

- **안 A (권장·범용): 통합 `GET /babies/{id}/sync/pull?since=<iso>`**
  → `{server_time, changes:{feedings:[...], sleeps:[...], ...}}`. 각 배열은 `updated_at > since`인 레코드(tombstone 포함). 한 번의 왕복으로 전 도메인 pull → 콜드스타트 서버에 왕복 최소화(중요). 첫 sync는 `since` 생략.
- **안 B (최소 변경): 도메인별 GET에 `?since=` 파라미터 추가**
  → 기존 `?date=` 라우터에 `updated_at > since` 필터 옵션. 변경은 작지만 도메인당 1왕복(8회) → 콜드스타트에 불리.
- **결정: 안 A**. 왕복 수가 콜드스타트/슬립 서버에서 성패를 가르므로 통합 pull이 맞다. 대칭으로 **통합 push `POST /babies/{id}/sync/push`** 도 두어(`{feedings:[...], ...}` 배치 upsert + `{accepted, rejected, server_time}` 반환) 왕복 최소화.

### 5.5 변경 요약 (백로그)

1. 전 레코드 모델 + `updated_at`, `deleted_at` (2컬럼) + 마이그레이션(백필).
2. Create/Update 유스케이스: 클라 id 수용 + upsert + 서버 재타임스탬프.
3. Delete: 물리→soft-delete. 조회에 `deleted_at IS NULL`.
4. `POST /babies/{id}/sync/push` (배치 upsert), `GET /babies/{id}/sync/pull?since=` (증분·tombstone 포함).
5. (baby 자체도 동일 규칙 — 단 baby 삭제는 드묾, MVP는 baby pull만.)

---

## 6. UX / 신뢰성

- **오프라인 완결**: 읽기/쓰기 전부 로컬 → 서버 상태와 무관하게 즉시 성공. 스피너 없음.
- **동기화 상태 표시**(전역 `SyncCoordinator` @Observable, Feature는 이것만 관찰 — 엔티티 오염 없음):
  - `syncing`(회전) / `offline`(회색 구름) / `synced`(체크, 마지막 성공시각) / `error`(재시도 버튼).
  - 개별 레코드에 배지 안 붙임(신생아 앱엔 과함). 홈 상단 얇은 상태줄 1개로 충분.
- **실패 처리**: push 실패는 조용히 dirty 유지 + 백그라운드 재시도. 사용자에게는 "동기화 대기 N건"만 노출(불안 유발 최소화). 반복 실패(예: 401)만 명시적 알림.
- **공동양육 준실시간**: 포그라운드 중 30~60s 폴링 pull + 포그라운드 복귀 즉시 pull. (WebSocket/푸시는 Render 무료·복잡도상 MVP 밖. 폴링으로 "몇십 초 내 반영" 달성 → 신생아 공동양육엔 충분.)
- **데이터 유실 0**: dirty가 SwiftData에 영속 → 앱 강제종료·크래시·서버 다운 어떤 조합에도 미전송분이 살아남아 다음 트리거에 재전송. (A′ 대비 이 설계의 결정적 이득.)

---

## 7. 마이그레이션 계획 — 단계적 슬라이스 (리스크를 슬라이스별로 격리)

리스크 순위: **양방향 병합(pull merge) 버그 > push 멱등 > 로컬 영속**. 그래서 위험한 것을 **뒤로**, 안전한 것을 앞으로 배치하고, 한 도메인으로 먼저 검증한다.

### 슬라이스 0 — 로컬 영속 부활 (양방향 0, 리스크 최저)
- SwiftData `@Model` + Mapper + `AppModelContainer` 재도입(§2). `SchemaV1` 새로 생성(빈 스토어).
- `LocalFeedingRepository`(로컬 즉시 R/W, 아직 서버 안 씀). AppContainer에서 Feeding만 Local로 교체.
- **검증**: Feeding 오프라인 조회·작성이 서버 없이 완결. Feature 무변경 확인. **동기화 0줄** → 병합 버그 원천 차단.

### 슬라이스 1 — 백엔드 준비 (독립·병렬 가능)
- §5.1~5.3(컬럼+upsert+soft-delete) 배포. 기존 클라(현 server-first iOS)는 여전히 동작(추가 컬럼 무해).
- §5.4 `/sync/push`·`/sync/pull` 엔드포인트 추가(feeding부터).

### 슬라이스 2 — **단방향 Push MVP** (feeding 한 도메인)
- SyncEngine: **push만** 구현(pull 미구현). 로컬 dirty → 서버 upsert → markSynced.
- 트리거: 로컬 변경 디바운스 + 포그라운드. **pull이 없어 병합 충돌 리스크 0** — 가장 위험한 코드를 아직 안 켬.
- **검증**: 기기 A에서 작성 → 서버 DB에 반영. 재시도 멱등(중복 없음). 앱 재시작 후 미전송분 재전송(유실 0).

### 슬라이스 3 — **양방향(Pull merge) 켜기** (feeding)
- `applyRemote` LWW + tombstone + 커서(§4.3~4.4) 구현. push→pull 순서.
- **집중 테스트**(가장 위험): 두 기기 동시 편집, 삭제 vs 수정, 시계 오차, 오프라인 후 재합류, 첫 전량 pull. 여기 버그를 feeding 하나에 가둔다.
- **검증**: 부모 A/B 다기기 수렴 정확. delete-wins. 로컬-서버 최종 일치.

### 슬라이스 4 — 전 도메인 롤아웃
- 슬라이스 2~3에서 확정된 패턴을 sleep/diaper/play/growth/vaccination/baby에 복제(도메인당 Local repo + Model + 병합훅). SyncEngine은 도메인 목록만 확장.
- 통합 push/pull에 도메인 배열 추가. 슬라이스 3에서 패턴이 검증됐으므로 각 도메인은 **기계적 복제**.

### 슬라이스 5 — UX 마감
- SyncCoordinator 상태줄, 폴링, 재시도 UI, 401 처리. 감사로그(선택).

**MVP 첫 단계 = 슬라이스 0~2** (로컬 영속 + 백엔드 upsert + feeding 단방향 push). 이 지점에서 이미 "오프라인 작성 + 유실 0"이 달성된다(가장 큰 사용자 가치). 양방향(공유 수렴)은 슬라이스 3부터.

---

## 8. 미해결 트레이드오프 / 리스크

1. **진행중 세션(활성 수면)의 동시 종료**: 두 부모가 같은 세션을 각각 종료 → LWW로 늦은 `ended_at`이 이긴다. 대개 무해하나 "먼저 종료가 맞다" 케이스는 못 잡음. 필드 병합 없이 수용(빈도 낮음).
2. **폴링 vs 실시간**: 30~60s 폴링은 "동시에 같은 화면 보며 협업"엔 지연 체감 가능. WebSocket은 Render 무료·서버 슬립과 상성 나쁨 → 보류. 필요 시 APNs 배경 푸시로 pull 트리거(후속).
3. **LWW의 은밀한 손실**: 진 쪽 변경이 조용히 사라짐. 신생아 기록 특성상 드물지만 0은 아님. 감사로그/토스트로 완화 가능하나 MVP 밖.
4. **baby 삭제·양육자 탈퇴의 tombstone 전파**: 공유 해제 시 상대 로컬 캐시 정리 규칙은 별도 설계 필요(MVP는 baby 삭제 미지원으로 회피).
5. **스키마 진화**: 향후 도메인 필드 추가 시 SwiftData `SchemaMigrationPlan` + 서버 마이그레이션 양쪽 필요. `SchemaV1` 래핑으로 대비만 해둠.
6. **백엔드 upsert 권한**: 클라 id를 신뢰하되, 반드시 JWT user_id ↔ baby 소유/합류 검증을 upsert 경로에도 적용(타인 id 위조 삽입 방지).
