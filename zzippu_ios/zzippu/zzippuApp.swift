// App/zzippuApp.swift
// @main — AppContainer 조립 (SwiftData ModelContainer 제거)

import SwiftUI

@main
struct zzippuApp: App {
    @State private var appContainer = AppContainer()
    @State private var toastCenter = ToastCenter()

    var body: some Scene {
        WindowGroup {
            // ToastHost 오버레이를 먼저 얹고 그 위에 environment 를 적용해야
            // ToastHost 도 toastCenter 환경을 상속받는다(순서 중요 — 아니면 크래시).
            AppRootView()
                .overlay(alignment: .bottom) {
                    ToastHost()
                }
                .environment(appContainer)
                .environment(\.theme, .zzippu)
                .environment(toastCenter)
        }
    }
}
