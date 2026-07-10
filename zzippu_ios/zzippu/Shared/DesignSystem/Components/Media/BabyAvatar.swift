// Shared/DesignSystem/Components/Media/BabyAvatar.swift
// 아기 프로필 아바타.
// size: sm(32) / lg(80). 원형. AsyncImage 실패 시 성별 그라데이션 + 👶 fallback.

import SwiftUI

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
    public let photoURL: URL?
    public let gender:   BabyGender
    public let size:     BabyAvatarSize

    public init(
        photoURL: URL? = nil,
        gender:   BabyGender = .unknown,
        size:     BabyAvatarSize = .sm
    ) {
        self.photoURL = photoURL
        self.gender   = gender
        self.size     = size
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        Group {
            if let url = photoURL {
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
                fallbackView
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .clipShape(Circle())
    }

    // MARK: Fallback

    private var fallbackView: some View {
        ZStack {
            Circle()
                .fill(gradientForGender)
            Text("👶")
                .font(.system(size: size.fontSize))
        }
    }

    private var gradientForGender: LinearGradient {
        switch gender {
        case .male:
            return LinearGradient(
                colors: [
                    theme.color.domainFeedingFormulaSolid.color.opacity(0.7),
                    theme.color.primaryTint.color
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
        case .female:
            return LinearGradient(
                colors: [
                    theme.color.domainFeedingBreastLeftSolid.color.opacity(0.7),
                    theme.color.domainFeedingBreastBothTint.color
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
        case .unknown:
            return LinearGradient(
                colors: [
                    theme.color.domainSleepSolid.color.opacity(0.5),
                    theme.color.primaryTint.color
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
        }
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
