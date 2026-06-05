# 찌뿌둥 UX 개선 + UI 교체 가능 클린아키텍처 — 실행계획

> 멀티에이전트 회의(5영역 진단 + 종합, 2026-06-05) 산출. 관통 원칙:
> **UI(디자인)는 자유롭게 교체 가능하되, 도메인/엔티티/DB 계약은 불변.**
> 프론트 캐싱·hydration·표현계층만 조정하면 서버/도메인 무변경으로 핵심 UX를 해결할 수 있다.

## 핵심 진단 요약
사용자 체감 2대 문제:
- **(A) 데이터 깜빡임** — 새로고침/탭이동/날짜전환 시 기록이 사라졌다 나타남.
  지배 원인: ① QueryProvider gcTime/persist 미설정(새로고침 시 인메모리 캐시 소실)
  ② useDayRecords placeholderData 부재(날짜 키 전환 시 이전 데이터 즉시 제거)
  ③ DayTimeline의 isLoading/isEmpty 독립 판정(로딩 중 data=[]일 때 '기록 없음' 잠깐 노출).
- **(B) 헤더 아기정보 싱크** — hydration 전 기본값('우리 아기') 노출 + 로그아웃 시 babyStore 미초기화.

## 3단계 9액션

### 1단계 — UX 출혈 봉합 (즉시)
- **P1 (S)** DayTimeline 로딩/빈상태 판정 정상화 + 각 useQuery `placeholderData:(prev)=>prev` + 스켈레톤.
- **P2 (M)** babyStore hydration 게이팅 + `resetAllStores()`(로그아웃/신원전환 시 전체 초기화) + 헤더 게이팅.
- **P3 (M)** persistQueryClient(localStorage) + gcTime 30분+ + refetchInterval 15s→30~60s.

### 2단계 — 도메인 경계·SoT 정리
- **P4 (M)** 성공/에러 피드백 일원화(toast 통일, alert 제거) + 타이머(수면/놀이) 종료 캐시 반영 점검.
- **P5 (L)** Baby 단일 SoT — GET 후 store+query 동시 갱신 wrapper, `initializeBaby()` 통합.
- **P6 (M)** 설정 아기정보 수정 원자화 — store 래퍼에서 API 성공 시에만 커밋+실패 롤백, 컴포넌트는 API 직접 호출 제거.

### 3단계 — UI 교체 가능성 (표현계층 분리)
- **P7 (M)** TimelineScrollView pin 유지 기준/스크롤 복원 race 보정, oldestOffset을 uiStore 보존.
- **P8 (L)** 디자인 토큰 도입(color/spacing/radius/typography) + 활동색 중앙 맵(activityColorToken).
- **P9 (L)** 크로스도메인 결합 분리 — dateTimeAdapter/typeMapper 중앙화 → validator 추출 → headless 폼 훅 → activityRegistry + DTO→UIModel adapter.

## 진행 상태
- ⏳ 1단계(P1~P3) 착수 — 사용자 핵심 불만 해결.
- 2·3단계는 각 항목 독립 적용(신생아 육아 중 안전성 위해 빅뱅 금지, 점진 PR).

## 클린아키텍처 불변식 (모든 작업 공통 준수)
- 백엔드 DTO/enum/DB 스키마는 건드리지 않는다(이미 운영 데이터 존재).
- 캐시/hydration/스토어 생명주기 = 인프라 정책. 서버가 단일 진실 소스.
- 색·간격·타이포 = 디자인 토큰(표현계층). 활동 종류 = 도메인 계약.
- UI 컴포넌트는 API client를 직접 import하지 않고 훅/스토어 래퍼를 통한다(점진 이관).
