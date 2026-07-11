// Data/Sync/NetworkMonitor.swift
// NWPathMonitor 래퍼 — 오프라인→온라인 전환 시 콜백 (동기화 트리거용, §4.5).

import Foundation
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "sync.network.monitor")
    private var wasSatisfied = true
    private let onReconnect: @Sendable () -> Void

    init(onReconnect: @escaping @Sendable () -> Void) {
        self.onReconnect = onReconnect
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let satisfied = path.status == .satisfied
            // 오프라인→온라인 상승 에지에서만 트리거
            if satisfied && !self.wasSatisfied {
                self.onReconnect()
            }
            self.wasSatisfied = satisfied
        }
        monitor.start(queue: queue)
    }

    func stop() { monitor.cancel() }
}
