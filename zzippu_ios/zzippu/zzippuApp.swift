// App/zzippuApp.swift
// @main — AppContainer 조립 (SwiftData ModelContainer 제거)

import SwiftUI

@main
struct zzippuApp: App {
    @State private var appContainer = AppContainer()
    @State private var toastCenter = ToastCenter()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appContainer)
                .environment(\.theme, .zzippu)
                .environment(toastCenter)
                .overlay(alignment: .bottom) {
                    ToastHost()
                }
        }
    }
}
