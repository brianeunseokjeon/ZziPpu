// Domain/Repositories/GuidelineRepository.swift
// 소아과 가이드 데이터 조회(읽기 전용) — Foundation only.
// Data 레이어가 번들 JSON을 로드해 구현. UseCase는 이 프로토콜에만 의존.

import Foundation

protocol GuidelineRepository {
    /// 연령/체중 파생 권장 범위 묶음(수유·수면·기저귀·터미타임 + 면책·출처).
    func pediatricGuideline() throws -> PediatricGuideline

    /// WHO 성장 백분위 밴드(성별×지표). 이번 슬라이스는 최소 데이터.
    func whoGrowthTable(metric: WHOGrowthMetric, sex: WHOGrowthSex) throws -> WHOGrowthTable
}
