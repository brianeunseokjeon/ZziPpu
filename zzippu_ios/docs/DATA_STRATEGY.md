> ⛔ **DEPRECATED (2026-07 폐기).** 이 local-first 전략은 **`DATA_STRATEGY_SERVER_FIRST.md`로 대체**되었다.
> 양육자 공유가 핵심 가치로 확정되어 서버가 진실의 원천이 되었다. 아래 내용(SwiftData 진실원천·sync 메타 4필드·pendingSync 훅)은 **구현하지 말 것**. 전환 절차는 `MIGRATION_PLAN.md` 참조. 이 파일은 이력 보존용으로만 남긴다.

---

# DATA_STRATEGY.md — local-first 데이터 전략 (★폐기됨 · 이력 보존★)

> 목표: 지금은 **회원가입·로그인만 서버**, 나머지 모든 기록은 로컬(SwiftData). 나중에 "로컬 → 서버 push" 동기화를 **거의 공짜**로 붙일 수 있도록 스키마·리포지토리 경계를 설계한다.
> 레이어·DI는 ARCHITECTURE.md, 필드 근거는 PRODUCT_SPEC.md.

---

## 1. SwiftData `@Model` 스키마 전체

### 1.1 모든 엔티티 공통 — 동기화 대비 필드 (필수)
웹의 각 record가 가진 `id, babyId, ...도메인필드..., createdAt` 에 더해, **미래 서버 동기화를 위한 메타 4종**을 모든 @Model에 강제로 넣는다. 이 4개가 "거의 공짜 동기화"의 핵심이다.

| 필드 | 타입 | 의미 |
|------|------|------|
| `id` | `UUID` `@Attribute(.unique)` | 클라가 생성하는 전역 고유 ID. 서버 붙어도 그대로 PK → ID 재매핑 불필요 |
| `updatedAt` | `Date` | 마지막 로컬 수정 시각. 증분 동기화의 커서 + LWW(Last-Write-Wins) 병합 기준 |
| `syncState` | `Int`(SyncState raw) | `localOnly(0)` / `dirty(1)` / `synced(2)` — push 대상 판별 |
| `deletedAt` | `Date?` | **soft delete**. 삭제도 서버에 전파해야 하므로 물리삭제 대신 tombstone |

`SyncState`(Domain/Values):
```swift
enum SyncState: Int, Codable, Sendable {
    case localOnly = 0   // 한 번도 서버에 안 감(신규 생성)
    case dirty     = 1   // 서버엔 있으나 로컬에서 수정됨(재push 필요)
    case synced    = 2   // 서버와 일치
}
```
규칙: create 시 `localOnly`, update 시 이미 synced였다면 `dirty`, delete 시 `deletedAt=now`이고 `dirty`(또는 localOnly면 물리삭제 가능). 서버 push 성공 시 `markSynced` → `synced`.

### 1.2 도메인별 @Model (Data/Persistence/Models)
> 이 @Model들은 **영속화 전용(PersistenceModel)** 이다. 도메인 로직은 순수 struct(§2)가 담당.

```swift
// 공통 매크로 없이 각 모델에 4개 메타필드를 반복 선언(값 semantics 명확·SwiftData 호환).

@Model final class FeedingModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var feedingTypeRaw: String        // FeedingType raw (formula/breast_left/…)
    var amountMl: Int?
    var durationMinutes: Int?
    var startedAt: Date
    var endedAt: Date?
    var memo: String?
    var createdAt: Date
    // sync meta
    var updatedAt: Date
    var syncStateRaw: Int
    var deletedAt: Date?
    init(...) { ... }
}

@Model final class SleepModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var startedAt: Date
    var endedAt: Date?                 // nil = 진행중(활성 세션)
    var durationMinutes: Int?
    var memo: String?
    var createdAt: Date
    var updatedAt: Date; var syncStateRaw: Int; var deletedAt: Date?
}

@Model final class DiaperModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var diaperTypeRaw: String          // pee/poo/both
    var stoolColorRaw: String?         // yellow/green/…
    var stoolStateRaw: String?         // liquid/soft/normal/hard
    var recordedAt: Date
    var memo: String?
    var createdAt: Date
    var updatedAt: Date; var syncStateRaw: Int; var deletedAt: Date?
}

@Model final class PlayModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var playTypeRaw: String            // tummy_time/free_play/sensory_play
    var durationMinutes: Int
    var startedAt: Date
    var endedAt: Date?
    var memo: String?
    var createdAt: Date
    var updatedAt: Date; var syncStateRaw: Int; var deletedAt: Date?
}

@Model final class GrowthModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var recordedAt: Date
    var weightG: Int?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var memo: String?
    var createdAt: Date
    var updatedAt: Date; var syncStateRaw: Int; var deletedAt: Date?
}

@Model final class VaccinationModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var vaccineName: String
    var doseNumber: Int
    var scheduledDate: Date
    var administeredDate: Date?         // nil = 미접종. (isOverdue/daysUntil은 computed, 저장 안 함)
    var hospitalName: String?
    var memo: String?
    var createdAt: Date
    var updatedAt: Date; var syncStateRaw: Int; var deletedAt: Date?
}

@Model final class BabyModel {
    @Attribute(.unique) var id: UUID
    var userId: UUID?                   // 서버 user와 연결(로그인 시 채움)
    var name: String
    var birthDate: Date
    var genderRaw: String               // male/female/unknown
    var birthWeightG: Int?
    var photoData: Data?                // 아바타(로컬)
    var createdAt: Date
    var updatedAt: Date; var syncStateRaw: Int; var deletedAt: Date?
}
```

- **저장하지 않는 것**: DailySummary, Prediction, Trend, isOverdue/daysUntil, 나이(ageDays) → 전부 **로컬 파생 계산**(UseCase). development/vaccination 프리셋은 **번들 정적 리소스**(Shared/Resources), @Model 아님.
- AI/caregiver 관련 @Model은 **지금 만들지 않는다**(후순위). 필요 시 동일한 4메타필드 규약으로 추가.
- 스키마 버전관리: `SchemaV1: VersionedSchema`로 감싸 두어 향후 마이그레이션(예: 동기화용 서버ID 필드 추가) 시 `SchemaMigrationPlan` 으로 안전 이행.

---

## 2. 순수 Domain 엔티티(struct) ↔ @Model 분리 — **분리 채택**

**결론: 분리한다.** Domain은 `struct`(값 타입, Sendable, 프레임워크 무지), Data는 `@Model class`.

트레이드오프 정리:
- 분리 비용: Mapper 1개/엔티티(모델↔struct 변환) 보일러플레이트.
- 분리 이득: (1) Domain/UseCase가 `import SwiftData` 없이 순수 유지 → 모듈화·단위테스트 용이. (2) SwiftData `@Model`은 참조타입·컨텍스트 바운드라 뷰/스레드 전파 시 위험 → 값 struct로 경계를 넘겨 안전. (3) 미래 서버 DTO도 같은 struct로 매핑되어 로컬/원격 소스가 대칭.
- 신생아앱 규모에서 Mapper 비용은 작고, 클린아키텍처·동기화 대비 이득이 크므로 **실용적으로도 분리가 우세**.

```swift
// Domain/Entities — 순수
struct Feeding: Identifiable, Equatable, Sendable {
    let id: UUID
    let babyId: UUID
    var type: FeedingType
    var amountMl: Int?
    var durationMinutes: Int?
    var startedAt: Date
    var endedAt: Date?
    var memo: String?
    let createdAt: Date
    // 동기화 메타도 엔티티에 노출(리포지토리가 다룸)
    var updatedAt: Date
    var syncState: SyncState
    var deletedAt: Date?
}

// Data/Persistence/Mappers
extension FeedingModel {
    func toEntity() -> Feeding {
        Feeding(id: id, babyId: babyId, type: FeedingType(rawValue: feedingTypeRaw)!,
                amountMl: amountMl, durationMinutes: durationMinutes,
                startedAt: startedAt, endedAt: endedAt, memo: memo, createdAt: createdAt,
                updatedAt: updatedAt, syncState: SyncState(rawValue: syncStateRaw) ?? .localOnly,
                deletedAt: deletedAt)
    }
    func apply(_ e: Feeding) {   // 업데이트 매핑
        feedingTypeRaw = e.type.rawValue; amountMl = e.amountMl
        durationMinutes = e.durationMinutes; startedAt = e.startedAt
        endedAt = e.endedAt; memo = e.memo
        updatedAt = e.updatedAt; syncStateRaw = e.syncState.rawValue; deletedAt = e.deletedAt
    }
}
```

매핑 규칙: 조회는 `deletedAt == nil` 필터를 Repository에서 항상 적용(soft delete는 UI에 안 보임). enum raw는 Mapper에서만 변환(Domain은 enum, 저장은 String).

---

## 3. Repository 프로토콜 설계 (Domain) — CRUD + 동기화 훅

모든 도메인 Repository가 따르는 공통 형태. **동기화 훅(`pendingSync`/`markSynced`)을 지금 프로토콜에 넣어 두는 것**이 미래 비용을 0으로 만드는 장치다(구현은 MVP 단계에서 로컬만 다루면 됨).

```swift
protocol Repository {
    associatedtype Entity: Identifiable
    // --- 로컬 CRUD (MVP에서 실제로 쓰는 것) ---
    func create(_ entity: Entity) throws
    func update(_ entity: Entity) throws       // updatedAt=now, synced였으면 dirty로
    func softDelete(id: UUID) throws            // deletedAt=now, dirty
    func fetch(id: UUID) throws -> Entity?
    // --- 미래 동기화 훅 (MVP에선 호출 안 함, 구현만 존재) ---
    func pendingSync(babyId: UUID) throws -> [Entity]   // syncState != synced 인 것 + tombstone
    func markSynced(ids: [UUID], serverTime: Date) throws
    func applyRemote(_ remote: [Entity]) throws         // pull 병합(LWW by updatedAt)
}
```

도메인별 조회 메서드는 각 프로토콜에 추가(예: `FeedingRepository.list(babyId:on:)`, `SleepRepository.activeSession(babyId:)`, `GrowthRepository.series(babyId:)`).

MVP 구현 예(SwiftData):
```swift
final class SwiftDataFeedingRepository: FeedingRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func create(_ e: Feeding) throws {
        let m = FeedingModel(from: e)          // syncState=.localOnly, updatedAt=now
        context.insert(m); try context.save()
    }
    func update(_ e: Feeding) throws {
        guard let m = try fetchModel(e.id) else { return }
        var next = e; next.updatedAt = .now
        if m.syncStateRaw == SyncState.synced.rawValue { next.syncState = .dirty }
        m.apply(next); try context.save()
    }
    func softDelete(id: UUID) throws {
        guard let m = try fetchModel(id) else { return }
        m.deletedAt = .now; m.updatedAt = .now
        m.syncStateRaw = SyncState.dirty.rawValue; try context.save()
    }
    func list(babyId: UUID, on day: Date) throws -> [Feeding] {
        let (s,e) = day.dayBounds
        let p = #Predicate<FeedingModel> {
            $0.babyId == babyId && $0.deletedAt == nil && $0.startedAt >= s && $0.startedAt < e
        }
        return try context.fetch(FetchDescriptor(predicate: p,
                 sortBy: [.init(\.startedAt, order: .reverse)])).map { $0.toEntity() }
    }
    // pendingSync / markSynced / applyRemote — 구현돼 있으나 MVP에선 미호출
    func pendingSync(babyId: UUID) throws -> [Feeding] {
        let synced = SyncState.synced.rawValue
        let p = #Predicate<FeedingModel> { $0.babyId == babyId && $0.syncStateRaw != synced }
        return try context.fetch(FetchDescriptor(predicate: p)).map { $0.toEntity() }
    }
    func markSynced(ids: [UUID], serverTime: Date) throws { /* set syncState=.synced */ }
    func applyRemote(_ remote: [Feeding]) throws { /* LWW upsert by updatedAt */ }
}
```

---

## 4. 동기화 마이그레이션 시나리오 — "거의 공짜"임을 코드 경계로 증명

지금 코드에 **동기화 흔적은 데이터 필드 4개 + 프로토콜 훅뿐**이고, 실제 네트워크 코드는 0줄이다. 나중에 서버를 붙일 때 추가되는 것은 딱 아래 3가지이며, **기존 Feature/Domain/UseCase/기존 Repository 조회 로직은 한 줄도 바뀌지 않는다.**

추가되는 코드(전부 Data 레이어에 국한):
1. `Data/Sync/RemoteDataSource` — URLSession으로 서버 `POST /sync/push`, `GET /sync/pull?since=` 호출. (DTO ↔ Domain struct 매핑은 §2의 Mapper 패턴 재사용.)
2. `Data/Sync/SyncService` — 오케스트레이션:
   ```
   for each domain repo:
       let dirty = repo.pendingSync(babyId)      // 이미 존재하는 훅
       let acked = remote.push(dirty)            // 서버 업서트(id 그대로, tombstone 포함)
       repo.markSynced(acked.ids, serverTime)    // 이미 존재하는 훅
       let changes = remote.pull(since: lastCursor)
       repo.applyRemote(changes)                 // LWW 병합
   ```
3. App에서 `SyncService`를 `.task`/백그라운드/포그라운드 복귀 시 트리거하는 호출 1~2줄.

왜 거의 공짜인가(불변식으로 증명):
- **로컬이 진실의 원천(source of truth) 유지**: UI는 계속 로컬만 읽는다. 동기화는 백그라운드에서 로컬을 업서트할 뿐, 화면 코드 무변경.
- **클라 생성 UUID = 서버 PK**: ID 재매핑/충돌 처리 불필요.
- **증분 push**: `syncState != synced` 만 보내므로 전량 전송 없음. `updatedAt` 커서로 pull.
- **soft delete(tombstone)**: 삭제도 일반 레코드처럼 전파되어 특별 처리 불필요.
- **LWW 병합**: `updatedAt` 비교로 충돌 해결 규칙이 단순·결정적(공동양육 다기기에도 그대로 적용).
- **경계 봉인**: Feature는 Repository 프로토콜만 알고 SyncService의 존재조차 모른다 → 동기화 추가가 상위 레이어에 새지 않음.

즉 미래 작업 = "Data/Sync 폴더 채우기 + App에서 트리거". 이것이 설계로 예약해 둔 §2(폴더 트리)의 `Data/Sync/`, Repository의 3개 훅, @Model의 4개 메타필드의 존재 이유다.

---

## 5. 인증(서버) vs 로컬 저장의 경계

| 구분 | 저장소 | 이유 |
|------|--------|------|
| `accessToken`(JWT) | **Keychain** (`KeychainTokenStore`, Data/Auth) | 민감정보. UserDefaults·SwiftData 금지 |
| `userId`, `isNewUser`, `termsRequired` | @AppStorage / UserDefaults | 비민감 세션 플래그 |
| 약관 동의(agreeTerms) | 서버 API(호출만) | auth-service 소유 |
| **그 외 모든 기록(feeding/sleep/diaper/play/growth/vaccination/baby)** | **SwiftData(로컬)** | local-first. 네트워크 없이 완결 |
| development/vaccination 프리셋 | 번들 정적 리소스 | 콘텐츠, 변하지 않음 |

경계 규칙:
- 네트워크를 아는 코드는 **오직 `Data/Auth`**(로그인/약관)뿐. 나머지 Repository는 URLSession을 모른다. → 동기화 붙기 전까지 "서버를 아는 표면적"이 auth 한 곳으로 최소화됨(웹의 `authClient`/`apiClient` 분리 철학 계승).
- 로그인 성공 시 서버 `userId`를 로컬 `BabyModel.userId`에 채워, 훗날 동기화가 소유권을 판별할 수 있게 미리 연결.
- 토큰 만료: `AuthRepository`가 401 감지 → 재로그인 유도(자동 재발급 정책은 auth-service 스펙에 맞춤). 로컬 기록은 토큰과 무관하게 항상 접근 가능(오프라인 우선).

---

## 6. 개발 착수 순서 (수직 슬라이스 우선순위)

각 슬라이스는 **Domain → Data(@Model+Repo+Mapper) → Feature(View+VM) → App 조립**을 end-to-end로 완성한다. 순서는 아키텍처 검증 가치와 사용자 체감가치 순.

1. **[기반] SwiftData/DI 스캐폴딩** — 템플릿 `Item` 제거, `SchemaV1`, `AppContainer`, `AppRootView`(분기), 공통 `Repository`/`SyncState`/Mapper 패턴, DesignSystem 뼈대. (동작하는 빈 탭)
2. **[수직슬라이스 1: Feeding]** — 가장 빈번한 기록으로 전 레이어 패턴을 확정(엔티티/모델/매퍼/리포/뷰모델/입력시트/타임라인/퀵세이브+undo/soft delete). 이후 도메인은 이 패턴 복제.
3. **[수직슬라이스 2: Diaper + Sleep]** — Diaper(색/상태 시트)로 옵션필드 패턴, Sleep으로 **활성 세션(진행중 타이머)** 패턴 확립.
4. **[Home 통합]** — BigActionGrid + DayTimeline + ActiveSessionBanner + 날짜 네비게이터로 위 3도메인을 홈에 통합(웹 Phase 9 대응).
5. **[Play + Growth]** — Play(간단), Growth(입력 + Swift Charts 성장곡선, 온보딩 출생체중 자동 1건).
6. **[Auth + Onboarding]** — 이메일 OTP 로그인, Keychain 토큰, 약관 동의, 아기 온보딩. (여기서 처음이자 유일하게 서버 연동. 앞 단계는 시드 baby로 개발 가능.)
7. **[Dashboard + Trends]** — 로컬 파생 계산(DailySummary/Prediction/Trend UseCase) + 차트. 저장 없음.
8. **[Vaccination + Development]** — 번들 프리셋 로딩, 접종 완료 체크, 발달 스테이지 조회(읽기 전용).
9. **[후순위] Sync + AI + Caregiver** — `Data/Sync` 채우기(§4대로 훅 연결), 이후 AI 리뷰/상담·공동양육자. 이 단계에서 상위 레이어 변경 없음이 설계의 최종 검증.

권장: 1~4를 먼저 끝내면 "밤중 수유·기저귀·수면 기록"이라는 앱의 핵심가치가 오프라인으로 완결되어 실사용 가능. 5~8로 완성도, 9로 서버 확장.
