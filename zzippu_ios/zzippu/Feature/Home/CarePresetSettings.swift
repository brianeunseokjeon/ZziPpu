// Feature/Home/CarePresetSettings.swift
// 영양제·약 이름 프리셋 영속 저장소(UserDefaults). 사용자가 추가/삭제 가능.
// QuickBarSettings 패턴(enum 네임스페이스 + JSON 배열).

import Foundation
import os

enum CarePresetSettings {

    private static let log = Logger(subsystem: "com.zzippu.app", category: "CarePresetSettings")

    // MARK: - 카테고리별 키/기본값

    private static func key(for category: CareCategory) -> String {
        "carepresets.\(category.rawValue)"
    }

    /// 기본 프리셋. 목욕은 프리셋 없음.
    static func defaults(for category: CareCategory) -> [String] {
        switch category {
        case .supplement: return ["유산균", "비타민D", "유산균&비타민D"]
        case .medicine:   return ["감기약", "장염약", "해열제"]
        case .bath:       return []
        case .hospital:   return []
        }
    }

    // MARK: - get

    /// 저장된 프리셋(미설정이면 기본값). 순서=표시 순서.
    static func presets(for category: CareCategory) -> [String] {
        guard let json = UserDefaults.standard.string(forKey: key(for: category)),
              let data = json.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data)
        else {
            return defaults(for: category)
        }
        return arr
    }

    // MARK: - mutate

    /// 프리셋 추가(중복·공백 무시, 맨 끝). 반환 = 갱신된 목록.
    @discardableResult
    static func add(_ name: String, to category: CareCategory) -> [String] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return presets(for: category) }
        var list = presets(for: category)
        guard !list.contains(trimmed) else { return list }
        list.append(trimmed)
        save(list, for: category)
        return list
    }

    /// 프리셋 삭제. 반환 = 갱신된 목록.
    @discardableResult
    static func remove(_ name: String, from category: CareCategory) -> [String] {
        var list = presets(for: category)
        list.removeAll { $0 == name }
        save(list, for: category)
        return list
    }

    private static func save(_ list: [String], for category: CareCategory) {
        guard let data = try? JSONEncoder().encode(list),
              let json = String(data: data, encoding: .utf8)
        else {
            log.error("CarePresetSettings: 저장 실패(\(category.rawValue, privacy: .public))")
            return
        }
        UserDefaults.standard.set(json, forKey: key(for: category))
    }
}
