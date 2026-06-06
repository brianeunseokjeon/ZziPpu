# 수유량 적정성 카드 — 3대 작업 개발 계획

> 계획 수립: Opus 4.8 에이전트 (2026-06-06)
> 구현: Sonnet 4.6 멀티에이전트

---

## 핵심 사실 (사전 조사 확정)

1. **버그 원인 확정**: 백엔드 `CreateGrowthRequest.recorded_at`는 Pydantic `date`(`YYYY-MM-DD`만 허용). `FeedingAdequacyCard`가 `new Date().toISOString()`(datetime) 을 보내 → **422**.
2. **백엔드 `birth_weight_g` 완전 지원**: 엔티티·모델·DTO·레포·`BabyCreateRequest`·`BabyUpdateRequest` 모두 존재. 프론트 UI만 미노출.
3. **casing 자동 변환**: api-client가 camelCase→snake_case 변환. `recorded_at`/`weight_g`는 이미 snake라 그대로 통과.

---

## 작업 (1) 체중 입력 버그 수정 + WeightInline 공용화 [최최우선]

### 수정 파일
- `frontend/src/features/dashboard/components/FeedingAdequacyCard.tsx`
- `frontend/src/features/growth/components/WeightInline.tsx` (신규 추출)
- `frontend/src/lib/date-utils.ts` (todayDateString 헬퍼 추가)

### 변경 핵심
```ts
// AS-IS
data: { recorded_at: new Date().toISOString(), weight_g: Math.round(kg * 1000) }

// TO-BE (GrowthForm과 동일)
data: { recorded_at: new Date().toISOString().slice(0, 10), weight_g: Math.round(kg * 1000) }
```

- `date-utils.ts`에 `todayDateString()` 헬퍼 추가 (중복 제거)
- `WeightInline`을 `features/growth/components/WeightInline.tsx`로 승격(export)
- 저장 중 중복 방지: `disabled={create.isPending}`
- 실패 피드백: `onError` 토스트 추가

### 의존성
독립적. 가장 먼저.

---

## 작업 (2) 체중 입력 위치 추가 — 설정 + 온보딩

### 설계 결정 (SSOT)
- **SSOT = growth records**
- 온보딩 출생 체중 → `baby.birth_weight_g` **+ 출생일자 growth record 1건 생성**(대시보드 동기화)
- 설정 현재 체중 → growth record 생성 (baby 프로필 건드리지 않음)

### 2-A 설정 페이지
**수정 파일**: `frontend/src/app/(main)/settings/page.tsx`

```tsx
const { data: records } = useGrowthRecords(babyId);
const weightG = records?.find((r) => r.weight_g != null)?.weight_g ?? null;
// 생년월일 행 아래:
<WeightInline babyId={babyId} weightG={weightG} />
```

### 2-B 온보딩 페이지
**수정 파일**: `frontend/src/app/(auth)/onboarding/page.tsx`

```tsx
// 상태 추가
const [birthWeightKg, setBirthWeightKg] = useState("");

// baby 생성 시
const birthWeightG = kg > 0 && kg <= 50 ? Math.round(kg * 1000) : null;
await apiClient.post("/api/v1/babies", { name, birthDate, gender, birthWeightG });

// baby 생성 성공 후 growth record 생성
if (birthWeightG) {
  await apiClient.post(`/api/v1/babies/${baby.id}/growth`, {
    recorded_at: birthDate, weight_g: birthWeightG,
  }).catch(() => {}); // 실패해도 온보딩 진행
}
```

### 의존성
**(1) 선행 필수** — WeightInline 공용 컴포넌트 재사용

---

## 작업 (3) AAP 권장 수유량 문구 검증

### 수정 파일
- `frontend/src/features/dashboard/lib/feedingGuideline.ts`
- `frontend/src/features/dashboard/components/FeedingAdequacyCard.tsx`

### 검증 결과
- 코드의 150~180 ml/kg/일, cap 960 ml/일은 AAP 기준(≈163 ml/kg/일, 32oz≈960ml)과 정합
- **수치는 그대로, 출처·면책 강화**

### 변경 내용
feedingGuideline.ts 주석에 공식 출처 명시:
```
* 근거: AAP / HealthyChildren.org "Amount and Schedule of Baby Formula Feedings"
* 통용 기준: 약 2.5 oz/lb/일 (≈ 165 ml/kg/일), 1일 최대 약 32 oz (≈ 960 ml)
* ⚠️ 참고용 일반 가이드이며 의학적 진단이 아님
```

면책 UI에 출처 1줄 추가:
```
"AAP(미국소아과학회)·HealthyChildren.org 기준. 의학적 진단이 아닌 참고용입니다."
```

### 의존성
(1)(2)와 독립. 병렬 가능.

---

## 전체 순서

| 단계 | 작업 | 병렬 여부 |
|------|------|-----------|
| 1 | (1) 버그 수정 + WeightInline 공용화 | 단독 선행 |
| 2 | (2a) 설정 + (2b) 온보딩 체중 입력 | 서로 병렬 |
| 2 | (3) AAP 문구 검증 | (2)와 병렬 |
| 3 | 커밋·배포 | 전체 완료 후 |
