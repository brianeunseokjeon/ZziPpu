// Shared/DesignSystem/Components/Media/BabyAvatar.swift
// 아기 프로필 아바타.
// size: sm(32) / lg(80). 원형. AsyncImage 실패 시 성별 그라데이션 + 👶 fallback.

import SwiftUI
import UIKit

// MARK: - BabyGender

/// DesignSystem 내부 성별 키. 도메인 엔티티 비의존.
public enum BabyGender {
    case male
    case female
    case unknown
}

// MARK: - BabyAvatarSize

public enum BabyAvatarSize {
    case sm  // 32pt — 헤더
    case lg  // 80pt — 프로필

    var diameter: CGFloat {
        switch self {
        case .sm: return 32
        case .lg: return 80
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .sm: return 16
        case .lg: return 36
        }
    }
}

// MARK: - BabyAvatar

public struct BabyAvatar: View {
    public let photoURL:   URL?
    /// 기기-로컬 대표 이미지(서버 미업로드). 있으면 최우선 표시.
    public let localImage: UIImage?
    public let gender:     BabyGender
    public let size:       BabyAvatarSize

    public init(
        photoURL:   URL? = nil,
        localImage: UIImage? = nil,
        gender:     BabyGender = .unknown,
        size:       BabyAvatarSize = .sm
    ) {
        self.photoURL   = photoURL
        self.localImage = localImage
        self.gender     = gender
        self.size       = size
    }

    @Environment(\.theme) private var theme

    /// AsyncImage는 http(s) 원격 URL만 로드해야 함. 스킴 없는/로컬 URL을 주면
    /// LocalDownloadTask로 시도하다 error -10을 뱉으므로, 원격 URL만 통과시킨다.
    private var remotePhotoURL: URL? {
        guard let url = photoURL,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return nil }
        return url
    }

    public var body: some View {
        Group {
            if let localImage {
                // ① 기기-로컬 대표 이미지(최우선)
                Image(uiImage: localImage)
                    .resizable()
                    .scaledToFill()
            } else if let url = remotePhotoURL {
                // ② 서버 사진 URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                // ③ 기본 마스코트
                fallbackView
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .clipShape(Circle())
    }

    // MARK: Fallback

    /// 사진이 없을 때의 기본 캐릭터. 성별과 무관하게 동일한 "찌뿌둥" 마스코트(에셋 이미지).
    private var fallbackView: some View {
        Image("MascotDefault")
            .resizable()
            .scaledToFill()
    }
}

// MARK: - Preview

#Preview("BabyAvatar") {
    HStack(spacing: 24) {
        VStack(spacing: 8) {
            BabyAvatar(gender: .male,    size: .sm)
            BabyAvatar(gender: .female,  size: .sm)
            BabyAvatar(gender: .unknown, size: .sm)
        }
        VStack(spacing: 8) {
            BabyAvatar(gender: .male,    size: .lg)
            BabyAvatar(gender: .female,  size: .lg)
            BabyAvatar(gender: .unknown, size: .lg)
        }
    }
    .padding()
    .environment(\.theme, .zzippu)
}
