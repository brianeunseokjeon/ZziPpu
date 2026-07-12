// Shared/DesignSystem/Theme/Theme+zzippu.swift
// 찌뿌둥 앱 기본 테마 조립.
// 생성된 SemanticColorTokens / SemanticTypography / PrimitiveScale / PrimitiveShadow 를 조합.

import SwiftUI

extension Theme {
    /// 찌뿌둥 앱 기본 테마. 앱 루트에서 @Environment(\.theme) 으로 주입.
    static let zzippu: Theme = {
        let sc = SemanticColorTokens.default
        let ty = SemanticTypography.default

        // MARK: Color
        let color = ThemeColor(
            background:      sc.background,
            surface:         sc.surface,
            surfaceElevated: sc.surfaceElevated,
            surfaceSunken:   sc.surfaceSunken,
            primary:           sc.primary,
            primaryPressed:    sc.primaryPressed,
            onPrimary:         sc.onPrimary,
            primaryTint:       sc.primaryTint,
            primaryDisabledBg: sc.primaryDisabledBg,
            onPrimaryDisabled: sc.onPrimaryDisabled,
            textPrimary:     sc.textPrimary,
            textStrong:      sc.textStrong,
            textSecondary:   sc.textSecondary,
            textTertiary:    sc.textTertiary,
            border:          sc.border,
            borderStrong:    sc.borderStrong,
            // R1(웹정합): 라이트에서도 border-gray-100 상시 표시(웹 카드 정합). sc.border = gray-100/gray-700.
            cardBorder:      sc.border,
            divider:         sc.divider,
            scrim:           sc.scrim,
            statusSuccessFg:     sc.statusSuccessFg,
            statusSuccessBg:     sc.statusSuccessBg,
            statusSuccessSolid:  sc.statusSuccessSolid,
            statusWarningFg:     sc.statusWarningFg,
            statusWarningBg:     sc.statusWarningBg,
            statusWarningSolid:  sc.statusWarningSolid,
            statusDangerFg:      sc.statusDangerFg,
            statusDangerBg:      sc.statusDangerBg,
            statusDangerSolid:   sc.statusDangerSolid,
            statusInfoFg:        sc.statusInfoFg,
            statusInfoBg:        sc.statusInfoBg,
            statusInfoSolid:     sc.statusInfoSolid,
            domainFeedingFormulaSolid:     sc.domainFeedingFormulaSolid,
            domainFeedingFormulaTint:      sc.domainFeedingFormulaTint,
            domainFeedingBreastLeftSolid:  sc.domainFeedingBreastLeftSolid,
            domainFeedingBreastLeftTint:   sc.domainFeedingBreastLeftTint,
            domainFeedingBreastRightSolid: sc.domainFeedingBreastRightSolid,
            domainFeedingBreastRightTint:  sc.domainFeedingBreastRightTint,
            domainFeedingBreastBothSolid:  sc.domainFeedingBreastBothSolid,
            domainFeedingBreastBothTint:   sc.domainFeedingBreastBothTint,
            domainFeedingSolidsSolid:      sc.domainFeedingSolidsSolid,
            domainFeedingSolidsTint:       sc.domainFeedingSolidsTint,
            domainDiaperPeeSolid:  sc.domainDiaperPeeSolid,
            domainDiaperPeeTint:   sc.domainDiaperPeeTint,
            domainDiaperPoopSolid: sc.domainDiaperPoopSolid,
            domainDiaperPoopTint:  sc.domainDiaperPoopTint,
            domainDiaperBothSolid: sc.domainDiaperBothSolid,
            domainDiaperBothTint:  sc.domainDiaperBothTint,
            domainStoolYellow: sc.domainStoolYellow,
            domainStoolGreen:  sc.domainStoolGreen,
            domainStoolBrown:  sc.domainStoolBrown,
            domainStoolBlack:  sc.domainStoolBlack,
            domainStoolRed:    sc.domainStoolRed,
            domainStoolWhite:  sc.domainStoolWhite,
            domainSleepSolid: sc.domainSleepSolid,
            domainSleepTint:  sc.domainSleepTint,
            domainPlaySolid:  sc.domainPlaySolid,
            domainPlayTint:   sc.domainPlayTint,
            domainCheckupSolid: sc.domainCheckupSolid,
            domainCheckupTint:  sc.domainCheckupTint,
            quickButton: { kind in
                switch kind {
                case .formula:
                    return QuickButtonColors(
                        idleBg: sc.quickButtonFormulaIdleBg, idleBorder: sc.quickButtonFormulaIdleBorder, idleText: sc.quickButtonFormulaIdleText,
                        activeBg: sc.quickButtonFormulaActiveBg, activeBorder: sc.quickButtonFormulaActiveBorder, activeText: sc.quickButtonFormulaActiveText
                    )
                case .breast:
                    return QuickButtonColors(
                        idleBg: sc.quickButtonBreastIdleBg, idleBorder: sc.quickButtonBreastIdleBorder, idleText: sc.quickButtonBreastIdleText,
                        activeBg: sc.quickButtonBreastActiveBg, activeBorder: sc.quickButtonBreastActiveBorder, activeText: sc.quickButtonBreastActiveText
                    )
                case .pee:
                    return QuickButtonColors(
                        idleBg: sc.quickButtonPeeIdleBg, idleBorder: sc.quickButtonPeeIdleBorder, idleText: sc.quickButtonPeeIdleText,
                        activeBg: sc.quickButtonPeeActiveBg, activeBorder: sc.quickButtonPeeActiveBorder, activeText: sc.quickButtonPeeActiveText
                    )
                case .poo:
                    return QuickButtonColors(
                        idleBg: sc.quickButtonPooIdleBg, idleBorder: sc.quickButtonPooIdleBorder, idleText: sc.quickButtonPooIdleText,
                        activeBg: sc.quickButtonPooActiveBg, activeBorder: sc.quickButtonPooActiveBorder, activeText: sc.quickButtonPooActiveText
                    )
                case .sleep:
                    return QuickButtonColors(
                        idleBg: sc.quickButtonSleepIdleBg, idleBorder: sc.quickButtonSleepIdleBorder, idleText: sc.quickButtonSleepIdleText,
                        activeBg: sc.quickButtonSleepActiveBg, activeBorder: sc.quickButtonSleepActiveBorder, activeText: sc.quickButtonSleepActiveText
                    )
                case .play:
                    return QuickButtonColors(
                        idleBg: sc.quickButtonPlayIdleBg, idleBorder: sc.quickButtonPlayIdleBorder, idleText: sc.quickButtonPlayIdleText,
                        activeBg: sc.quickButtonPlayActiveBg, activeBorder: sc.quickButtonPlayActiveBorder, activeText: sc.quickButtonPlayActiveText
                    )
                }
            }
        )

        // MARK: Typography
        let typography = ThemeTypography(
            display:       ty.display,
            title:         ty.title,
            headline:      ty.headline,
            headlineStrong: ty.headlineStrong,
            body:          ty.body,
            bodyStrong:    ty.bodyStrong,
            callout:       ty.callout,
            caption:       ty.caption,
            captionStrong: ty.captionStrong,
            label:         ty.label,
            mono:          ty.mono,
            input:         ty.input
        )

        // MARK: Space
        let space = ThemeSpace(
            componentPaddingX: 16,
            componentPaddingY: 12,
            cardPadding:       20,
            screenPaddingX:    16,
            screenPaddingY:    16,
            sectionGap:        16,
            stackGapSm:        8,
            stackGapMd:        12,
            inlineGap:         8,
            xs: 4,
            sm: 8,
            md: 16,
            lg: 24,
            xl: 32
        )

        // MARK: Radius
        let radius = ThemeRadius(
            control:   PrimitiveScale.radiusMd,
            controlLg: PrimitiveScale.radiusControlLg,
            card:      PrimitiveScale.radiusLg,
            sheet:     PrimitiveScale.radiusXl,
            pill:      PrimitiveScale.radiusFull
        )

        // MARK: Shadow
        let shadow = ThemeShadow(
            sm: PrimitiveShadow.shadowSm,
            md: PrimitiveShadow.shadowMd,
            lg: PrimitiveShadow.shadowLg,
            xl: PrimitiveShadow.shadowXl
        )

        // MARK: Motion
        let motion = ThemeMotion(
            fast:             DSMotion.fast,
            normal:           DSMotion.normal,
            slow:             DSMotion.slow,
            toastAutoDismiss: DSMotion.toastAutoDismiss,
            spring:           DSMotion.spring,
            springFast:       DSMotion.springFast
        )

        // MARK: Components
        let component = ComponentTokens(
            button: ComponentButtonTokens(
                heightSm:       36,
                heightMd:       44,
                heightLg:       56,
                minWidth:       44,
                paddingXMd:     20,
                radius:         PrimitiveScale.radiusMd,
                radiusLg:       PrimitiveScale.radiusControlLg,
                disabledOpacity: 0.5
            ),
            card: ComponentCardTokens(
                padding: 20,
                radius:  PrimitiveScale.radiusLg,
                shadow:  PrimitiveShadow.shadowSm
            ),
            input: ComponentInputTokens(
                height:   44,
                paddingX: 16,
                radius:   PrimitiveScale.radiusMd
            ),
            chip: ComponentChipTokens(
                paddingX: PrimitiveScale.space3_5,
                height:   44,
                radius:   9999
            ),
            iconButtonSize:      44,
            emptyStatePaddingY:  24,
            sectionHeaderPaddingY: 8,
            statusPillPaddingX:  PrimitiveScale.space2_5,
            statusPillPaddingY:  PrimitiveScale.space1,
            timelineDotSize:     PrimitiveScale.sizeDotMd,
            timelineDotSizeIdle: PrimitiveScale.sizeDotSm,
            calendarCell: ComponentCalendarCellTokens(
                minHeight:      52,
                spacing:        PrimitiveScale.space1,   // 4
                todayCircle:    PrimitiveScale.sizeIconLg, // 24
                underbarHeight: 3,
                eventDotSize:   6
            )
        )

        return Theme(
            color:      color,
            typography: typography,
            space:      space,
            radius:     radius,
            shadow:     shadow,
            motion:     motion,
            component:  component
        )
    }()
}
