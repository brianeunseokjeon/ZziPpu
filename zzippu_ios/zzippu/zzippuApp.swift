// App/zzippuApp.swift
// @main — AppContainer 조립 + SwiftData ModelContainer(feeding 파일럿) 배선 복구.

import SwiftUI
import SwiftData
import UserNotifications

@main
@MainActor
struct zzippuApp: App {
    // 알림 델리게이트 배선(포그라운드 표시 + 탭 처리). 로컬 알림은 Info.plist/백그라운드모드 불필요.
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var appDelegate
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
                .environment(\.theme, .zzippu)
                .environment(toastCenter)
                // --- 오프라인 인프라가 있을 때만 배선 (OFFLINE_TOGGLE_PLAN §1.3·§5) ---
                // server-only(offline nil)면 SwiftData 환경·syncCoordinator·모니터링을 전부 생략.
                .modifier(OfflineWiring(container: appContainer))
        }
        .onChange(of: scenePhase) { _, phase in
            // 포그라운드 복귀(앱 시작 포함) 시: 서버 선제 워밍(콜드 완충) + full sync.
            if phase == .active {
                appContainer.prewarmServer()          // /health 선제 핑 → 서버+Neon 각성
                appContainer.triggerFeedingFullSync() // server-only면 내부 no-op
                appContainer.refreshFeedingReminders() // 간격 모드: 최신 수유 기준 알림 재조정
            }
        }
    }
}

/// 알림 델리게이트 — 앱 시작 시 UNUserNotificationCenter.delegate 설정.
/// 이게 없으면 앱이 켜져 있을 때(포그라운드) 로컬 알림 배너가 안 뜬다(iOS 기본 억제).
final class NotificationAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// 포그라운드에서도 배너·소리·목록으로 표시.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}

/// 오프라인 인프라 조건부 배선 — OfflineInfra 가 있을 때만 SwiftData 컨테이너·syncCoordinator·
/// 네트워크 모니터링을 주입한다. server-only면 전부 no-op(SwiftData 런타임 완전 배제).
/// 제거 시 이 modifier 와 zzippuApp 의 `.modifier(OfflineWiring…)` 한 줄만 지우면 됨.
private struct OfflineWiring: ViewModifier {
    let container: AppContainer

    func body(content: Content) -> some View {
        if let modelContainer = container.modelContainer,
           let syncCoordinator = container.syncCoordinator {
            content
                .environment(syncCoordinator)          // 상태줄 UI(오프라인 전용)가 소비
                .modelContainer(modelContainer)         // feeding 로컬 영속(@ModelActor 공유)
                .task { container.startNetworkMonitoring() }
        } else {
            content    // server-only: SwiftData/동기화 미배선
        }
    }
}
