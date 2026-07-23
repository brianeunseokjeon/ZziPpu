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
            if let url = remotePhotoURL {
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

    /// 사진이 없을 때의 기본 캐릭터. 성별과 무관하게 동일한 "찌뿌둥" 얼굴을 보여준다.
    private var fallbackView: some View {
        DefaultBabyFace()
    }
}

// MARK: - DefaultBabyFace

/// 앱 마스코트("찌뿌둥") 얼굴을 벡터로 그린 기본 아바타.
/// - 에셋 이미지 대신 SwiftUI Canvas로 그려 어떤 크기에서도 선명함.
/// - 앱 아이콘(AppIconConcept.svg)과 동일한 조형(노랑 배경·감은 눈·미소·볼터치·머리컬).
struct DefaultBabyFace: View {
    var body: some View {
        Canvas { ctx, size in
            // 원본 아이콘은 380x380 좌표계 → 실제 크기로 스케일.
            let s = size.width / 380
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            let bg     = Color(red: 1.0,   green: 0.760, blue: 0.294) // #FFC24B
            let cheek  = Color(red: 0.949, green: 0.502, blue: 0.620) // #F2809E
            let ink    = Color(red: 0.169, green: 0.153, blue: 0.141) // #2B2724

            // 배경 (원형 클립은 BabyAvatar에서 적용).
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

            // 볼터치.
            ctx.fill(Path(ellipseIn: CGRect(x: (106 - 31) * s, y: (228 - 20) * s,
                                            width: 62 * s, height: 40 * s)),
                     with: .color(cheek.opacity(0.9)))
            ctx.fill(Path(ellipseIn: CGRect(x: (274 - 31) * s, y: (228 - 20) * s,
                                            width: 62 * s, height: 40 * s)),
                     with: .color(cheek.opacity(0.9)))

            // 감은 눈 ⌣⌣.
            var eyeL = Path(); eyeL.move(to: p(108, 182)); eyeL.addQuadCurve(to: p(168, 182), control: p(138, 216))
            var eyeR = Path(); eyeR.move(to: p(212, 182)); eyeR.addQuadCurve(to: p(272, 182), control: p(242, 216))
            // 미소.
            var smile = Path(); smile.move(to: p(146, 240)); smile.addQuadCurve(to: p(234, 240), control: p(190, 288))
            // 머리컬.
            var curl = Path()
            curl.move(to: p(186, 92))
            curl.addQuadCurve(to: p(219, 88),  control: p(202, 72))
            curl.addQuadCurve(to: p(220, 112), control: p(232, 100))

            ctx.stroke(eyeL,  with: .color(ink), style: StrokeStyle(lineWidth: 14 * s, lineCap: .round))
            ctx.stroke(eyeR,  with: .color(ink), style: StrokeStyle(lineWidth: 14 * s, lineCap: .round))
            ctx.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 15 * s, lineCap: .round))
            ctx.stroke(curl,  with: .color(ink), style: StrokeStyle(lineWidth: 12 * s, lineCap: .round))
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
