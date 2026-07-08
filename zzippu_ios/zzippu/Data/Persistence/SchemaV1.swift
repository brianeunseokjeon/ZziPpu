// Data/Persistence/SchemaV1.swift

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FeedingModel.self, BabyModel.self, GrowthModel.self]
    }
}

// MARK: - ModelContainer Factory

extension ModelContainer {
    /// 실제 디스크 영속 컨테이너
    static func makeProductionContainer() throws -> ModelContainer {
        let schema = Schema(SchemaV1.models, version: SchemaV1.versionIdentifier)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// 프리뷰/테스트용 인메모리 컨테이너
    static func makePreviewContainer() throws -> ModelContainer {
        let schema = Schema(SchemaV1.models, version: SchemaV1.versionIdentifier)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
