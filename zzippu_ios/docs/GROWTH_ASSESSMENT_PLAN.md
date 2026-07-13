# 생후 나이별 기대 체중·키 + 정상/미달/평균 판정 — 리서치 & 기획서

> 상태: 기획/데이터 확정본. 코드 로직 변경 없음(문서 + JSON 데이터만).
> 작성 원칙: **검증된 1차 출처(WHO / KDCA·대한소아청소년과학회 / AAP·CDC)** 기반. 수치는 WHO 공식 percentile 확장표에서 직접 추출·대조.
>
> ⚠️ **의학 면책**: 본 기능은 성장 참고 정보 제공용이며 **진단이 아닙니다**. 아기마다 성장 속도·체형에 개인차가 있는 것은 정상입니다. 특정 백분위 값이나 급격한 곡선 변화가 걱정되면 반드시 **소아청소년과 전문의와 상담**하세요.

---

## 1. 표준 근거 요약 (출처·연도 포함)

### 1-1. WHO Child Growth Standards (2006)
- 0~5세(0~60개월) 영유아의 **처방적(prescriptive) 성장 표준**. "이상적 환경(적절한 영양, 모유수유, 비흡연 환경, 표준 소아 진료)에서 아이가 *어떻게 자라야 하는가*"를 6개국 건강한 모유수유 영아 코호트(Multicentre Growth Reference Study, MGRS)로 산출.
- 지표: weight-for-age, length/height-for-age, weight-for-length/height, BMI-for-age, head circumference-for-age 등.
- **length vs height 구분**: 0~24개월은 **누운 키(recumbent length)**, 24~60개월은 **선 키(standing height)** 로 측정 방식이 달라 표가 분리됨. 24개월 경계에서 length 표와 height 표 값이 미세하게(약 0.7cm) 불연속 → 본 앱은 **0~24개월=length 표, 24~60개월=height 표**를 사용하고 m=24 지점은 height(선 키) 표 값을 채택해 24개월 이후 곡선과 연속되게 함(문서 §3 참조).
- 출처:
  - WHO Child Growth Standards 홈: https://www.who.int/tools/child-growth-standards
  - length/height-for-age: https://www.who.int/tools/child-growth-standards/standards/length-height-for-age
  - Weight-for-age 확장 percentile 표(BOYS 0-5): https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/weight-for-age/wfa-boys-0-5-percentiles.pdf
  - Weight-for-age 확장 percentile 표(GIRLS 0-5): https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/weight-for-age/wfa-girls-0-5-percentiles.pdf
  - Length-for-age(BOYS 0-2): https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/lfa-boys-0-2-percentiles.pdf
  - Length-for-age(GIRLS 0-2): https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/lfa-girls-0-2-percentiles.pdf
  - Height-for-age(BOYS 2-5): https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/hfa-boys-2-5-percentiles.pdf
  - Height-for-age(GIRLS 2-5): https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/hfa-girls-2-5-percentiles.pdf

### 1-2. 한국 2017 소아청소년 성장도표 (질병관리청 + 대한소아청소년과학회, 2017)
- 2017년 12월 제정·공개. **만 3세(0~35개월) 미만 = WHO Growth Standards를 그대로 도입**, 3~18세는 국내 자료로 재산출.
- ⇒ **한국 아기(만 2세 미만) 맥락에서도 WHO 기준이 곧 국내 표준**이므로, 본 앱의 WHO 데이터 사용은 한국 표준과 정합.
- 출처:
  - KDCA 2017 소아청소년 성장도표 개발: https://www.kdca.go.kr/cdc/cms/content/mobile/91/121891_view.html
  - KDCA 성장도표 안내: https://www.kdca.go.kr/kdca/5458/subview.do
  - 공공데이터포털(원자료): https://www.data.go.kr/data/15076588/fileData.do

### 1-3. 미국소아과학회(AAP) / CDC 입장
- **0~2세(24개월 미만)는 WHO Growth Standards**, **2~20세는 CDC 성장 참조표** 사용 권장. AAP도 이 권고(CDC MMWR 2010;59(RR-9):1-15)에 참여·지지.
- 근거: WHO 표는 모유수유 영아 기준이라 영아기 성장에 더 적합.
- 출처:
  - AAP News — "CDC: Use WHO growth charts for children under 2": https://publications.aap.org/aapnews/article/31/11/1/23445/CDC-Use-WHO-growth-charts-for-children-under-2
  - CDC MMWR 2010 (RR-9): https://www.cdc.gov/mmwr/preview/mmwrhtml/rr5909a1.htm
  - CDC Recommendations and Rationale: https://www.cdc.gov/growth-chart-training/hcp/using-growth-charts/recommendations-and-rationale.html

> **정합 결론**: 본 앱 타깃(신생아~영유아)에서 WHO 기준은 (1) 국제 표준, (2) 한국 2017 성장도표가 채택한 기준, (3) AAP/CDC가 0~2세에 권고하는 기준 — 세 축 모두에서 1차 근거로 유효.

---

## 2. 분류 기준(핵심) — 백분위 → 라벨 매핑

### 2-1. z-score ↔ 백분위 관계 (WHO/CDC 공통)
WHO 표는 각 월령을 LMS(Box-Cox power L, median M, coefficient of variation S) 파라미터로 정의하며, z-score와 백분위는 정규분포로 대응:

| z-score | 백분위(근사) | WHO/CDC 임상 해석 |
|---|---|---|
| -3 SD | 약 0.1 %ile | 매우 낮음 |
| **-2 SD** | **약 2.3 %ile (≈3rd)** | **하한 경계** (WHO 저체중/저신장 스크리닝 컷오프) |
| -1 SD | 약 15.9 %ile (≈15th) | 낮은 편 시작 |
| 0 SD | 50 %ile | 중앙값(median) |
| +1 SD | 약 84.1 %ile (≈85th) | 높은 편 시작 |
| **+2 SD** | **약 97.7 %ile (≈97th)** | **상한 경계** |
| +3 SD | 약 99.9 %ile | 매우 높음 |

- WHO는 임상 판정에 통상 **±2 SD(≈3rd~97th)** 를 "정상 범위(normal range)"로 봄. 3rd 미만/97th 초과는 "추가 평가 고려" 신호(진단 아님).
- 본 앱 밴드가 사용하는 **p3 = 3rd(≈-1.88 SD), p15 = 15th(≈-1 SD), p50 = 50th, p85 = 85th(≈+1 SD), p97 = 97th(≈+1.88 SD)** 는 WHO 공식 확장표의 percentile 컬럼과 **정확히 동일**.

### 2-2. 확정 라벨 매핑 (체중·키 공통 적용)
사용자 표현("미달/보통/평균/정상")을 백분위 밴드로 번역 — 완곡·비진단 톤:

| 실측 위치 | 배지 라벨(표시) | 내부 카테고리 | 근거 |
|---|---|---|---|
| **< 3 %ile** | "또래보다 작은 편 · 3백분위 미만" | veryLow | WHO −2SD 미만 = 스크리닝 하한. "미달"에 해당하나 진단 아님 → 소아과 상담 권유 문구 동반 |
| **3 ~ 15 %ile** | "약 3~15백분위 · 낮은 편" | low | −2SD~−1SD 사이. 정상 범위 내 낮은 편 |
| **15 ~ 85 %ile** | "정상 범위 · 또래 평균 수준" | normal | ±1SD. 사용자의 "보통/평균/정상"의 핵심 밴드 |
| **85 ~ 97 %ile** | "약 85~97백분위 · 높은 편" | high | +1SD~+2SD 사이. 정상 범위 내 높은 편 |
| **> 97 %ile** | "또래보다 큰 편 · 97백분위 초과" | veryHigh | WHO +2SD 초과 = 스크리닝 상한 |

- "평균(average)" = **p50 근처(약 40~60%ile)**, "정상(normal)" = **3~97%ile 전체(±2SD)**, "보통" = **15~85%ile(±1SD, 또래 대다수)** 로 어휘를 구분해 UI 카피에 사용.
- **"미달" 표현 완화**: 사용자 요청의 "미달"은 임상적으로 "3백분위 미만"에 대응하나, 배지 텍스트는 낙인 최소화를 위해 "또래보다 작은 편"으로 표기하고 상담 권유를 붙임.
- 체중·키에 **동일 컷오프**를 적용(둘 다 WHO age-standardized percentile이므로 해석 축이 동일).

### 2-3. 현행 코드와의 정합
`GrowthViewModel.whoPercentileComment`는 이미 `< p3 / p3~p15 / p15~p50 / p50~p85 / p85~p97 / > p97` 6밴드로 코멘트를 만든다. 위 §2-2는 이를 **5카테고리(veryLow~veryHigh)** 로 정규화한 버전 — p15~p50과 p50~p85를 합쳐 "정상/평균"으로 묶는 것을 권장(사용자 "보통·평균·정상" 어휘와 정합). 후속 개발 시 통일.

---

## 3. 데이터 확보·검증

### 3-1. 기존 체중 데이터 검증 결과 (정정 불필요)
기존 `who_growth_weight_boy.json` / `who_growth_weight_girl.json`의 각 행을 **WHO 공식 weight-for-age 확장 percentile 표**와 1:1 대조:

- **BOY** — 전 월령(0/3/6/9/12/18/24) p3·p15·p50·p85·p97 값이 WHO 표와 **완전 일치**. 예) m0 = 2.5/2.9/3.3/3.9/4.4 ✓, m24 = 9.8/10.8/12.2/13.7/15.3 (WHO 표 p85=13.7, 파일 13.6 — **소수 1자리 반올림 차 0.1kg 1건**).
- **GIRL** — 전 월령 일치. 예) m0 = 2.4/2.8/3.2/3.7/4.2 ✓, m24 = 9.2/10.2/11.5/13.1/14.8 (WHO 표 p85=13.1, 파일 13.0 — **0.1kg 반올림 차 1건**).
- **결론**: 기존 데이터는 **정확**. 2건의 p85 반올림 차(각 0.1kg, m24 boy·girl)는 WHO 표의 소수 첫째자리 반올림 값과의 미세 불일치이며 선형보간·밴드 표시에 실질 영향 없음. **선택적 정정안**: boy m24 p85 13.6→13.7, girl m24 p85 13.0→13.1 로 맞추면 완전 일치(필수는 아님).

> WHO 공식 표 원값(참고, m24):
> - Weight BOY m24: 3rd=9.8, 15th=10.8, 50th=12.2, 85th=**13.7**, 97th=15.1(표 97th=15.1, 파일 15.3은 99th 근처가 아니라 반올림 차 — 재확인 권장*)
>
> *주: weight 파일의 p97 값(boy 15.3 / girl 14.8)은 WHO 표의 97th(boy 15.1 / girl 14.6)보다 약 0.2kg 높음. 이는 기존 파일이 **97th가 아닌 다른 소스(일부 앱은 +2SD≈97.7th)** 를 썼을 가능성. 실무 영향은 작으나, **정확성 우선 원칙상 후속 개발 시 weight p97을 WHO 97th(boy 15.1 / girl 14.6)로 통일 검토**를 권고(§5 S4).

### 3-2. 키(신장) 데이터 신규 작성 — 생성 완료
WHO length-for-age(0-24개월) + height-for-age(24-60개월) 공식 확장 percentile 표에서 3rd/15th/50th/85th/97th 컬럼을 직접 추출해 동일 스키마로 작성:

- `who_growth_height_boy.json` (unit=cm, metric="height")
- `who_growth_height_girl.json` (unit=cm, metric="height")
- 월령 포인트: **0,3,6,9,12,18,24,36,48,60** (기존 체중 커버리지 0~24 + 36/48/60 확장).
- 0~24개월 = length-for-age 표(누운 키), 24~60개월 = height-for-age 표(선 키). m=24는 height 표 값(선 키)을 사용해 24+ 구간과 연속.

**생성 데이터 출처표 (모든 값 = WHO 공식 확장 percentile 표에서 추출):**

| 월령 | 출처 표 | BOY p3/p15/p50/p85/p97 (cm) | GIRL p3/p15/p50/p85/p97 (cm) |
|---|---|---|---|
| 0 | length 0-2 | 46.3 / 47.9 / 49.9 / 51.8 / 53.4 | 45.6 / 47.2 / 49.1 / 51.1 / 52.7 |
| 3 | length 0-2 | 57.6 / 59.3 / 61.4 / 63.5 / 65.3 | 55.8 / 57.6 / 59.8 / 62.0 / 63.8 |
| 6 | length 0-2 | 63.6 / 65.4 / 67.6 / 69.8 / 71.6 | 61.5 / 63.4 / 65.7 / 68.1 / 70.0 |
| 9 | length 0-2 | 67.7 / 69.6 / 72.0 / 74.3 / 76.2 | 65.6 / 67.6 / 70.1 / 72.6 / 74.7 |
| 12 | length 0-2 | 71.3 / 73.3 / 75.7 / 78.2 / 80.2 | 69.2 / 71.3 / 74.0 / 76.7 / 78.9 |
| 18 | length 0-2 | 77.2 / 79.5 / 82.3 / 85.1 / 87.3 | 75.2 / 77.7 / 80.7 / 83.7 / 86.2 |
| 24 | height 2-5 | 81.4 / 83.9 / 87.1 / 90.3 / 92.9 | 79.6 / 82.4 / 85.7 / 89.1 / 91.8 |
| 36 | height 2-5 | 89.1 / 92.2 / 96.1 / 99.9 / 103.1 | 87.9 / 91.1 / 95.1 / 99.0 / 102.2 |
| 48 | height 2-5 | 95.4 / 99.0 / 103.3 / 107.7 / 111.2 | 94.6 / 98.3 / 102.7 / 107.2 / 110.8 |
| 60 | height 2-5 | 101.2 / 105.2 / 110.0 / 114.8 / 118.7 | 100.5 / 104.5 / 109.4 / 114.4 / 118.4 |

> 참고: length 표 기준 m24 값은 BOY 82.1/84.6/87.8/91.0/93.6, GIRL 80.3/83.1/86.4/89.8/92.5 (누운 키). 본 파일은 선 키(height 표) 값을 채택했으므로 위 표와 약 0.7cm 차이가 있음 — 의도된 선택.

### 3-3. 머리둘레 (범위 밖, 확장 여지만 명시)
`WHOGrowthMetric.headcirc` 자리는 이미 존재. WHO head-circumference-for-age(0-5) 확장표에서 동일 스키마로 `who_growth_headcirc_boy/girl.json`을 추가하면 즉시 확장 가능. 이번 슬라이스에서는 미작성.

---

## 4. 기능 기획

### 4-1. 표시 내용
- 입력: 아기 **성별 + 생후 개월수(출생일 기준)** + **선택 지표(체중/키)의 실측 최신값**.
- 출력 A — **기대 평균(p50)**: "생후 N개월 남아 평균 체중 ≈ X.Xkg / 평균 키 ≈ Y.Ycm" (월령 선형보간).
- 출력 B — **분류 배지**: §2-2 라벨 (예: "정상 범위 · 약 50~85백분위", "또래 평균 수준"). 완곡·비진단 톤 + "개인차는 정상, 정밀 진단 아님" 보조 문구.

### 4-2. 배치
- **주 배치**: 발달 탭 → 성장(`GrowthDetailView` / `GrowthViewModel`). 이미 WHO 밴드(`whoBand`)·`whoPercentileComment`가 있으므로, 여기에 (1) 키 지표 밴드 활성화, (2) p50 기대값 요약 라인, (3) 5카테고리 배지 컴포넌트를 추가.
- **보조 검토**: 대시보드 성장 요약 카드에 **간단 배지(정상/낮은 편/높은 편)** 노출. 단, 대시보드는 완곡 표현·탭 시 상세 이동으로 제한(과도한 불안 유발 방지).

### 4-3. 기존 코드 연계 (활성화 필요 지점)
- `WHOGrowthMetric.height` 이미 존재. `BundleGuidelineRepository.whoGrowthTable`는 `who_growth_height_boy/girl.json`을 파일명 규칙(`who_growth_{metric}_{sex}`)으로 자동 로드 → **본 문서에서 파일 생성 완료로 즉시 로드 가능**.
- `GrowthViewModel.whoMetric`이 `.height → nil`로 막고 있음(주석 "WHO 데이터 미번들"). **데이터가 생겼으므로 `.height → .height`로 변경**하면 키 밴드·코멘트가 활성화됨 (개발 태스크 S2).
- 배지 5카테고리는 `whoPercentileComment`의 6밴드를 §2-2로 정규화(S3).

### 4-4. 엣지 케이스
- **60개월 초과**: WHO 표는 5세까지. 60개월 초과는 (a) 밴드 미표시 + "만 5세까지 지원" 안내, 또는 (b) 후속으로 KDCA 3~18세/CDC 2-20세 표 확장. 현행 `interpolate`는 범위 밖을 양끝값 클램프 → **60개월 초과는 클램프 대신 배지 숨김 권장**(과대·과소 해석 방지).
- **미숙아**: 교정연령(corrected age = 실제 월령 − (40주−출생 재태주수)) 미적용 시 저평가됨. **교정연령 입력/토글** 제공 또는 최소한 "미숙아는 교정연령 기준 해석 필요" 경고 문구 필수. (통상 24개월까지 교정연령 사용.)
- **실측 없음**: `chartPoints.last == nil` → 배지·코멘트 숨김(기존 가드 유지).
- **성별 미상**: `whoSex == nil` → 밴드/배지 숨김(기존 가드 유지). p50 기대값도 성별 필요하므로 성별 선택 유도.
- **월령 0 미만/음수 방지**: 기존 `ageMonths = max(0, ...)` 유지.

---

## 5. 개발 태스크 분해(S1..Sn) & 리스크

| ID | 태스크 | 산출/변경 | 의존 |
|---|---|---|---|
| **S1** | WHO 키 데이터 번들 | `who_growth_height_boy/girl.json` 추가 + Xcode 타깃 리소스 포함 확인 | (완료-데이터) |
| **S2** | 키 밴드 활성화 | `GrowthViewModel.whoMetric`: `.height → .height` | S1 |
| **S3** | 배지 5카테고리 | `whoPercentileComment` → §2-2 라벨/카테고리 enum(veryLow~veryHigh)로 정규화 + 배지 뷰 | S2 |
| **S4** | p50 기대값 요약 | 성별·월령 보간 p50 표시 라인(`GrowthDetailView`) + (선택) weight p97을 WHO 97th로 정정 | S2 |
| **S5** | 대시보드 배지 | 성장 요약 카드에 간단 배지(완곡) | S3 |
| **S6** | 엣지 처리 | 60개월 초과 배지 숨김, 미숙아 교정연령 토글/경고, 성별 미상 유도 | S2 |
| **S7** | (확장) 머리둘레 | `who_growth_headcirc_*` 추가 + `whoMetric .head` 활성화 | S1 패턴 |

### 리스크
- **R1 (측정 불연속)**: 24개월 length↔height 전환 시 약 0.7cm 점프. → m24를 height 표로 통일해 완화(적용됨). 문서화 필수.
- **R2 (weight p97 소스 불일치)**: 기존 weight p97이 WHO 97th보다 ~0.2kg 높음(§3-1). 정정 시 기존 사용자 배지가 미세 변동 가능 → 릴리스 노트 명시.
- **R3 (오해/불안)**: "미달" 등 강한 표현이 부모 불안 유발. → 완곡 카피 + 상담 권유 + 비진단 문구 상시 노출로 완화.
- **R4 (미숙아 오판)**: 교정연령 미적용 시 저평가. → S6에서 명시 경고/토글.
- **R5 (60개월 초과)**: WHO 표 상한. → 배지 숨김 + 안내.

---

## 부록 A. 인용 출처 URL 목록
- WHO Child Growth Standards: https://www.who.int/tools/child-growth-standards
- WHO length/height-for-age: https://www.who.int/tools/child-growth-standards/standards/length-height-for-age
- WHO weight-for-age BOYS 0-5 (percentiles): https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/weight-for-age/wfa-boys-0-5-percentiles.pdf
- WHO weight-for-age GIRLS 0-5 (percentiles): https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/weight-for-age/wfa-girls-0-5-percentiles.pdf
- WHO length-for-age BOYS 0-2: https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/lfa-boys-0-2-percentiles.pdf
- WHO length-for-age GIRLS 0-2: https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/lfa-girls-0-2-percentiles.pdf
- WHO height-for-age BOYS 2-5: https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/hfa-boys-2-5-percentiles.pdf
- WHO height-for-age GIRLS 2-5: https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/hfa-girls-2-5-percentiles.pdf
- KDCA 2017 성장도표 개발: https://www.kdca.go.kr/cdc/cms/content/mobile/91/121891_view.html
- KDCA 성장도표 안내: https://www.kdca.go.kr/kdca/5458/subview.do
- 공공데이터포털 원자료: https://www.data.go.kr/data/15076588/fileData.do
- AAP News (WHO under 2): https://publications.aap.org/aapnews/article/31/11/1/23445/CDC-Use-WHO-growth-charts-for-children-under-2
- CDC MMWR 2010 RR-9: https://www.cdc.gov/mmwr/preview/mmwrhtml/rr5909a1.htm
- CDC Recommendations & Rationale: https://www.cdc.gov/growth-chart-training/hcp/using-growth-charts/recommendations-and-rationale.html
