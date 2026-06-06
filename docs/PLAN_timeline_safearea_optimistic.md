# 3가지 UX 개선 — 개발 계획

> 계획 수립: Opus 4.8 (2026-06-06)
> 구현: Sonnet 4.6 멀티에이전트

---

## 작업 1: 타임라인 역순 (최신 위)

### 접근법: dates 배열 역순 + 하단 sentinel

**변경 파일:**
- `frontend/src/features/recording/components/TimelineScrollView.tsx`
- `frontend/src/features/recording/components/DayTimeline.tsx`

**핵심 변경:**
- `dates` = `[오늘, 어제, ...]` (역순)
- `groupByMinute` 정렬: `b.ts - a.ts` (내림차순)
- pinnedToBottomRef, ResizeObserver pin, prevScrollHeightRef 제거
- 상단 sentinel → 하단 sentinel (rootMargin 하단)
- "오늘로" 버튼: `distFromBottom > 200` → `el.scrollTop > 200`
- 마운트 시 scrollTop=0 (기본값이 오늘)

---

## 작업 2: SafeArea 전면 적용

### 접근법: globals.css @utility + Dialog content 패딩

**변경 파일:**
- `frontend/src/app/globals.css`
- `frontend/src/shared/components/ui/dialog.tsx`

**핵심 변경:**
```css
@utility pb-safe {
  padding-bottom: calc(env(safe-area-inset-bottom) + 1rem);
}
```
- Dialog content: `<div className="p-5 pb-safe">`
- TimelineScrollView 하단 여백: `<div className="pb-safe" />`

---

## 작업 3: 낙관적 업데이트 (diaper/sleep/play create)

### 접근법: optimisticCreate 헬퍼 신규 + 각 API 훅에 적용

**변경 파일:**
- `frontend/src/shared/lib/optimisticCreate.ts` (신규)
- `frontend/src/features/diaper/api/diaperApi.ts`
- `frontend/src/features/sleep/api/sleepApi.ts`
- `frontend/src/features/play/api/playApi.ts`

**RecordEditSheet.tsx 변경 없음** — 훅 내부에서 처리

**핵심:**
- delete는 이미 optimistic ✅
- create에 optimisticCreateOptions 적용 → delete+create가 화면상 원자적으로 보임
- onError에서 스냅샷 복원 (토스트는 RecordEditSheet catch에서만)

---

## 독립 순서
작업 3 → 2 → 1 (3이 가장 격리됨, 1이 가장 큰 리팩터)
