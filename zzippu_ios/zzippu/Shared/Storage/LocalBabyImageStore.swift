// Shared/Storage/LocalBabyImageStore.swift
// 아기 "대표 이미지"의 기기-로컬 저장소.
// - 서버에 업로드하지 않음 → 이 기기에서만 보이고 다른 기기와 공유되지 않는다(설계상 로컬 전용).
// - Application Support/baby_images/<babyId>.jpg 에 JPEG로 저장(용량 위해 최대 변 1024px 리사이즈).
// - 값이 바뀌면 didChange 알림 발행 → 홈/설정 아바타가 즉시 갱신.

import UIKit

final class LocalBabyImageStore {

    static let shared = LocalBabyImageStore()
    private init() {}

    /// 로컬 대표 이미지 변경 알림. object = 대상 babyId(UUID).
    static let didChange = Notification.Name("zzippu.localBabyImageDidChange")

    private let fm = FileManager.default

    /// 저장 디렉터리(없으면 생성). 백업 대상인 Application Support 사용.
    private var directory: URL {
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("baby_images", isDirectory: true)
        if !fm.fileExists(atPath: base.path) {
            try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }

    private func fileURL(for babyId: UUID) -> URL {
        directory.appendingPathComponent("\(babyId.uuidString).jpg")
    }

    /// 로컬 대표 이미지 존재 여부.
    func hasImage(for babyId: UUID) -> Bool {
        fm.fileExists(atPath: fileURL(for: babyId).path)
    }

    /// 로컬 대표 이미지 로드(없으면 nil).
    func loadImage(for babyId: UUID) -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL(for: babyId)) else { return nil }
        return UIImage(data: data)
    }

    /// 이미지 저장(최대 변 1024px 리사이즈 + JPEG 0.85). 성공 시 didChange 발행.
    @discardableResult
    func save(_ image: UIImage, for babyId: UUID) -> Bool {
        let resized = image.zzippu_downscaled(maxDimension: 1024)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return false }
        do {
            try data.write(to: fileURL(for: babyId), options: .atomic)
            NotificationCenter.default.post(name: Self.didChange, object: babyId)
            return true
        } catch {
            return false
        }
    }

    /// 로컬 대표 이미지 삭제(기본 마스코트로 복귀). didChange 발행.
    func delete(for babyId: UUID) {
        try? fm.removeItem(at: fileURL(for: babyId))
        NotificationCenter.default.post(name: Self.didChange, object: babyId)
    }
}

// MARK: - UIImage 리사이즈 헬퍼

private extension UIImage {
    /// 최대 변이 maxDimension 이하가 되도록 축소(이미 작으면 원본 유지). 종횡비 보존.
    func zzippu_downscaled(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
