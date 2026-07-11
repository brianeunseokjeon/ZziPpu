// App/zzippuApp.swift
// @main — AppContainer 조립 + SwiftData ModelContainer(feeding 파일럿) 배선 복구.

import SwiftUI
import SwiftData

@main
@MainActor
struct zzippuApp: App {
    @State private var appContainer = AppContainer()
    @State private var toastCenter = ToastCenter()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // ToastHost 오버레이를 먼저 얹고 그 위에 environment 를 적용해야
            // ToastHost 도 toastCenter 환경을 상속받는다(순서 중요 — 아니면 크래시).
            AppRootView()
                .overlay(alignment: .bottom) {
                    ToastHost()
                }
                .environment(appContainer)
                .environment(appContainer.syncCoordinator)   // 상태줄 UI는 S5에서 소비
                .environment(\.theme, .zzippu)
                .environment(toastCenter)
                // SwiftData: feeding 로컬 영속(@ModelActor가 컨테이너 공유)
                .modelContainer(appContainer.modelContainer)
                .task {
                    // 네트워크 복구 감지 → full sync 트리거
                    appContainer.startNetworkMonitoring()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // 포그라운드 복귀 시 full sync(밤중 재개 최신화)
            if phase == .active {
                appContainer.triggerFeedingFullSync()
            }
        }
    }
}
