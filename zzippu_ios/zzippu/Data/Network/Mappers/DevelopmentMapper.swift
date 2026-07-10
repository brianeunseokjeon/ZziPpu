// Data/Network/Mappers/DevelopmentMapper.swift
// DevelopmentDTO ↔ Domain Entity.

import Foundation

enum DevelopmentMapper {

    static func toEntity(_ dto: DevelopmentStageDTO) -> DevelopmentStage {
        let lower = dto.ageRangeDays.first ?? 0
        let upper = dto.ageRangeDays.count > 1 ? dto.ageRangeDays[1] : lower
        return DevelopmentStage(
            ageRangeDays: lower...max(lower, upper),
            label: dto.label,
            summary: dto.summary,
            grossMotor: dto.grossMotor,
            fineMotor: dto.fineMotor,
            cognition: dto.cognition,
            language: dto.language,
            social: dto.social,
            selfCare: dto.selfCare,
            parentActions: dto.parentActions.map(toAction),
            warningSigns: dto.warningSigns,
            feedingSummary: dto.feedingSummary,
            sleepSummary: dto.sleepSummary,
            playSummary: dto.playSummary,
            sources: dto.sources
        )
    }

    static func toBundle(_ dto: CurrentStageBundleDTO) -> DevelopmentStageBundle {
        DevelopmentStageBundle(
            current: toEntity(dto.current),
            previous: dto.previous.map(toEntity),
            next: dto.next.map(toEntity),
            ageDays: dto.ageDays
        )
    }

    static func toEntity(_ dto: MilestoneDTO) -> Milestone {
        Milestone(
            days: dto.days,
            label: dto.label,
            emoji: dto.emoji,
            category: Milestone.Category(rawValue: dto.category) ?? .developmental,
            description: dto.description
        )
    }

    // MARK: - Private

    private static func toAction(_ dto: ParentActionDTO) -> ParentAction {
        ParentAction(
            id: UUID(),
            icon: dto.icon,
            title: dto.title,
            detail: dto.detail,
            source: dto.source,
            priority: ParentAction.Priority(rawValue: dto.priority) ?? .medium
        )
    }
}
