// Shared/Extensions/Calendar+KST.swift
// KST(Asia/Seoul) 고정 Calendar/TimeZone 공용 유틸.
//
// 왜 필요한가:
//   기기 시간대(Calendar.current)를 쓰면 기기가 KST가 아닐 때 "오늘" 판별이
//   어긋난다(예: UTC 기기에서 KST 새벽 1시는 아직 전날). 웹은 Asia/Seoul 고정을
//   쓰므로, iOS도 표시·그룹핑·오늘판별을 KST로 통일한다.
//
// 규약:
//   • 저장/전송은 UTC 유지(서버 계약). 표시·그룹핑·오늘판별·날짜경계만 KST.
//   • 시간대 민감한 날짜 로직은 반드시 `Calendar.kst` / `TimeZone.kst` 를 쓴다.

import Foundation

extension TimeZone {
    /// 한국 표준시(Asia/Seoul). 실패 시 +9시간 고정 오프셋으로 폴백.
    static let kst: TimeZone = TimeZone(identifier: "Asia/Seoul")
        ?? TimeZone(secondsFromGMT: 9 * 3600)!
}

extension Calendar {
    /// KST 고정 그레고리력 캘린더(오늘 판별·startOfDay·날짜경계·그룹핑 전용).
    static let kst: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .kst
        cal.locale = Locale(identifier: "ko_KR")
        return cal
    }()
}
