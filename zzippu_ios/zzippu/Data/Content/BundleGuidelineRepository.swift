// Data/Content/BundleGuidelineRepository.swift
// GuidelineRepository 번들 JSON 구현 — 정적 가이드 데이터 로드·격리.
// 앱 번들의 Resources/Guidelines/*.json 을 디코딩. 첫 로드 후 캐시.

import Foundation

// MARK: - Errors

enum GuidelineLoadError: Error, LocalizedError {
    case resourceNotFound(String)
    case decodeFailed(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name):
            return "가이드 리소스를 찾을 수 없어요: \(name)"
        case .decodeFailed(let name, let underlying):
            return "가이드 파싱 실패(\(name)): \(underlying.localizedDescription)"
        }
    }
}

// MARK: - BundleGuidelineRepository

final class BundleGuidelineRepository: GuidelineRepository {

    private let bundle: Bundle
    private let decoder = JSONDecoder()

    // 캐시 (정적 데이터 — 앱 수명 동안 불변)
    private var cachedPediatric: PediatricGuideline?
    private var cachedGrowth: [String: WHOGrowthTable] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    // MARK: - Pediatric guideline

    func pediatricGuideline() throws -> PediatricGuideline {
        if let cached = cachedPediatric { return cached }
        let value: PediatricGuideline = try load("pediatric_guidelines")
        cachedPediatric = value
        return value
    }

    // MARK: - WHO growth

    func whoGrowthTable(metric: WHOGrowthMetric, sex: WHOGrowthSex) throws -> WHOGrowthTable {
        let name = "who_growth_\(metric.rawValue)_\(sex.rawValue)"
        if let cached = cachedGrowth[name] { return cached }
        let value: WHOGrowthTable = try load(name)
        cachedGrowth[name] = value
        return value
    }

    // MARK: - Private

    private func load<T: Decodable>(_ resource: String) throws -> T {
        // Guidelines 하위 폴더 또는 루트 어디에 복사되든 탐색.
        let url = bundle.url(forResource: resource, withExtension: "json", subdirectory: "Guidelines")
            ?? bundle.url(forResource: resource, withExtension: "json")
        guard let url else {
            throw GuidelineLoadError.resourceNotFound(resource)
        }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            throw GuidelineLoadError.decodeFailed(resource, underlying: error)
        }
    }
}
