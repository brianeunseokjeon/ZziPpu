// App/zzippuApp.swift
// @main — ModelContainer + AppContainer 조립

import SwiftUI
import SwiftData

@main
struct zzippuApp: App {
    @State private var appContainer: AppContainer

    init() {
        do {
            let modelContainer = try ModelContainer.makeProductionContainer()
            _appContainer = State(initialValue: AppContainer(modelContext: modelContainer.mainContext))
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appContainer)
        }
    }
}
