// AUTO-GENERATED — 손대지 말 것
// Source: docs/design-system/tokens.json
// Generator: tools/gen-tokens.mjs  (node tools/gen-tokens.mjs)
// ⚠️  이 파일을 직접 수정하면 토큰 재생성 시 덮어씁니다.

import CoreGraphics

// MARK: - Primitive Scale (internal — feature code 직접 사용 금지)

enum PrimitiveScale {
    static let space0: CGFloat = 0
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 20
    static let space6: CGFloat = 24
    static let space8: CGFloat = 32
    static let space10: CGFloat = 40
    static let space12: CGFloat = 48
    static let space1_5: CGFloat = 6
    static let space2_5: CGFloat = 10
    static let space3_5: CGFloat = 14
    static let radiusNone: CGFloat = 0
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusControlLg: CGFloat = 16
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 24
    static let radiusFull: CGFloat = 9999
    static let sizeTouchMin: CGFloat = 44
    static let sizeControlSm: CGFloat = 36
    static let sizeControlMd: CGFloat = 44
    static let sizeControlLg: CGFloat = 56
    static let sizeDotSm: CGFloat = 8
    static let sizeDotMd: CGFloat = 10
    static let sizeIconSm: CGFloat = 14
    static let sizeIconMd: CGFloat = 20
    static let sizeIconLg: CGFloat = 24
    static let fontWeightRegular: CGFloat = 400
    static let fontWeightMedium: CGFloat = 500
    static let fontWeightSemibold: CGFloat = 600
    static let fontWeightBold: CGFloat = 700
    static let fontScaleCaption2: CGFloat = 12
    static let fontScaleCaption: CGFloat = 12
    static let fontScaleFootnote: CGFloat = 13
    static let fontScaleSubheadline: CGFloat = 15
    static let fontScaleCallout: CGFloat = 14
    static let fontScaleBody: CGFloat = 14
    static let fontScaleHeadline: CGFloat = 16
    static let fontScaleTitle3: CGFloat = 18
    static let fontScaleTitle2: CGFloat = 22
    static let fontScaleTitle1: CGFloat = 28
    static let fontScaleDisplay: CGFloat = 36
    static let opacityDisabled: CGFloat = 0.5
    static let opacityMuted: CGFloat = 0.3
    static let opacityScrim: CGFloat = 0.4
    static let motionDurationInstant: CGFloat = 100
    static let motionDurationFast: CGFloat = 200
    static let motionDurationNormal: CGFloat = 300
    static let motionDurationSlow: CGFloat = 500
}

// MARK: - Primitive Motion
enum PrimitiveMotion {
    /// 100ms
    static let motionDurationInstant: Double = 0.1
    /// 200ms
    static let motionDurationFast: Double = 0.2
    /// 300ms
    static let motionDurationNormal: Double = 0.3
    /// 500ms
    static let motionDurationSlow: Double = 0.5
    /// 3500ms
    static let motionToastAutoDismissMs: Double = 3.5
}
