// Data/Persistence/Store/AppModelContainer.swift
// SwiftData ModelContainer + SchemaV1 (feeding 파일럿만 — 나머지 도메인은 후속 슬라이스)
// server-first 전환 때 @Model 을 전부 지웠으므로, 재도입은 "빈 스토어에서 새 SchemaV1 생성" (§7-0).

import Foundation
import SwiftData

/// 앱 전역 로컬 영속 스키마 (버전 래핑 — 향후 SchemaMigrationPlan 대비)
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FeedingModel.self]   // S4에서 sleep/diaper/play/growth 추가
    }
}

enum AppModelContainer {

    /// 앱 컨테이너 (디스크 영속).
    /// 실패(스키마 손상·마이그레이션 오류)를 **삼키지 않고 throw** — 상위(OfflineToggle)에서
    /// server-only 로 강등 판단한다. (force-try 인메모리 폴백 제거: OFFLINE_TOGGLE_PLAN §2.)
    static func makeThrowing() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
