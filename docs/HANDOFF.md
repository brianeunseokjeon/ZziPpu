# 찌뿌둥(ZziPpu) 인계 문서 — 미적용/제안/이슈

> 최종 업데이트: 2026-06-06. context clear 대비 작성. 다음 세션은 이 문서부터 읽고 이어가면 된다.
> 신생아 육아 기록 + AI 소아과 리뷰 서비스. MSA(프론트 + auth + core).

---

## 🔥 최우선 다음 작업 (대시보드 수유량 적정성 — 사용자 직접 요청, 미완)

> 직전에 `FeedingAdequacyCard`(대시보드 수유량 적정성, commit e206765)를 만들었으나 아래 3가지가 남음.
> **사용자 지시: "이거 다 에이전트끼리 의논해줘" → 멀티에이전트 회의(Workflow) 후 진행할 것.**

### (1) 🐛 체중 입력이 안 되는 버그 [최우선]
- 위치: `frontend/src/features/dashboard/components/FeedingAdequacyCard.tsx` 의 `WeightInline` → `useCreateGrowthRecord().mutate({ babyId, data: { recorded_at: new Date().toISOString(), weight_g } })`
- **진단 포인트**:
  - 기존 정상 동작하는 `frontend/src/features/growth/components/GrowthForm.tsx` 가 `recorded_at` 을 **어떤 형식**으로 보내는지 비교 (날짜 `YYYY-MM-DD` vs datetime ISO). 백엔드 `CreateGrowthRequest`(`backend/app/presentation/schemas/growth_schema.py`?)가 `recorded_at` 을 `date` 로 받으면 `toISOString()`(datetime) 은 422 가능.
  - api-client `snakelizeKeys` 는 camelCase만 snake 변환 — `data` 의 키가 이미 snake(`recorded_at`,`weight_g`)라 그대로 전송됨(정상). 단 중첩/형식 재확인.
  - 브라우저 콘솔/네트워크 탭에서 POST `/growth` 응답코드 확인 (422/400/500).
  - input `type=number` 값 바인딩·`save()` 호출 자체가 되는지도 확인.

### (2) 체중 입력 위치 추가 — 설정 + 온보딩
- 사용자: "체중 입력은 **설정쪽에 있고, 온보딩에도** 있어야 할 것 같아."
- **설정**: `frontend/src/app/(main)/settings/page.tsx` 아기 정보 통합 카드에 체중 입력/표시 행 추가 (이름·생일 편집 옆). 최신 체중 = `useGrowthRecords()[0].weight_g`.
- **온보딩**: `frontend/src/app/(auth)/onboarding/page.tsx` 에 출생 체중 입력 추가 → baby `birth_weight_g` 또는 첫 growth record 로 저장. (baby 생성 시 birth_weight_g 필드 이미 있음 — `BabyCreateRequest` 에 `birth_weight_g` 포함되는지 확인)
- 대시보드 인라인 입력과 **동일 데이터 소스(growth)** 로 동기화되게.

### (3) ⚠️ AAP 권장 수유량 문구 — 실제 자료 검증 후 재작성
- 사용자: "지금 문구는 다른 서비스에서 쓰는 문구다. **실제 AAP(또는 한국소아과학회)가 어떻게 권장하는지 검색**해서 정확히 다시 적어라."
- 현재 `FeedingAdequacyCard` 면책 문구 + `feedingGuideline.ts` 의 150~180ml/kg·960ml cap 수치를 **1차 출처(AAP/대한소아청소년과학회/healthychildren.org)** 로 검증.
  - WebSearch 로 "AAP infant formula feeding amount per day", "healthychildren.org formula feeding amount by weight", "대한소아청소년과학회 영아 수유량" 등 확인.
  - 일반 인용 수치: AAP/healthychildren.org 는 보통 **2.5 oz(약 75ml) per pound per day, 1일 최대 약 32oz(≈960ml)** 로 안내 (≈165ml/kg/일). 출처와 정확한 표현을 확인 후 수치·문구·출처표기 갱신.
  - 의학 정보이므로 **출처 명시 + "참고용, 진단 아님, 소아과 상담" 면책 유지**.

### 진행 방식
1. **멀티에이전트 회의(Workflow)**: ① 체중입력 버그 디버거 ② 설정/온보딩 체중입력 설계 ③ AAP 자료 리서치(WebSearch 포함) → 통합 검수.
2. 회의 결과로 수정 → 빌드 → 커밋 → 배포.

---

---

## 0. 현재 운영 상태 (배포 완료, 동작 중)

| 구성 | 위치 | 비고 |
|------|------|------|
| 프론트 | Vercel — `https://zzippu.co.kr` | `zzi-ppu.vercel.app` → 307 redirect. Root Dir = `frontend` |
| auth 백엔드 | Render — `https://zzippu-auth.onrender.com` | 이메일 OTP, JWT 발급. 무료(15분 후 sleep→콜드스타트) |
| core 백엔드 | Render — `https://zzippu-core.onrender.com` | 기록/AI, JWT 검증 |
| DB | Neon Postgres | 양 서비스 공유. `?ssl=require` |
| GitHub | `git@github.com:brianeunseokjeon/ZziPpu` | main 브랜치 자동배포(Vercel/Render) |
| 도메인 | 가비아 (zzippu.co.kr) | A `@`→`216.198.79.1`, CNAME `www`→`da09491089e5953c.vercel-dns-017.com.`(또는 cname.vercel-dns.com) |
| 이메일 | Resend + zzippu.co.kr 도메인 인증됨 | `EMAIL_FROM=찌뿌둥 <onboarding@zzippu.co.kr>` |

**시크릿 위치(실값은 git 금지):** `SECRET_KEY`·`INTERNAL_API_KEY`는 `~/.claude/plans/temporal-waddling-bee.md` 상단 + Render 대시보드 env. `DATABASE_URL`/`RESEND_API_KEY`/`ANTHROPIC_API_KEY`는 Render env(+로컬 `.env`, gitignore됨). `render.yaml`은 모두 `sync:false`.

**운영 데이터 핵심 ID:**
- 실제 유저: `essy1224@naver.com`, user_id = `0e6cb47e-57e1-425e-a5a1-04183743dfaf`
- 실제 아기: baby_id = `00000000-0000-0000-0000-000000000002` ("우리 아기", male, 생일 2026-04-22)
- 로컬 SQLite → Neon 마이그레이션 완료 (수유40·기저귀32·예방접종34·수면1·채팅1대화6메시지)

---

## 1. 🔴 서버 안전장치가 막아서 못 한 것 (운영 DB 직접 조작)

자동 권한 분류기가 **운영 Neon DB의 DELETE/UPDATE를 2회 차단**했다. 코드로 불가, 사용자 승인 또는 Bash 권한 규칙 추가 필요.

### (a) 운영 DB 테스트 더미 정리
- 검증 중 만든 **테스트 아기 ~8개**(name: "테스트아기"/"디버그"/"날짜검증"/"t"/"t2" 등) + 딸린 기록이 남아있음.
- **영향 없음**: 다른 user_id에 묶여 사용자 화면엔 안 보임. DB만 지저분.
- 정리 SQL 개념: `babies` 및 자식 테이블에서 `baby_id != '00000000-0000-0000-0000-000000000002'` 삭제, `users`에서 `id != '0e6cb47e-...'` 삭제. (트랜잭션, 실제 데이터 보존)

### (b) 깨진 photo_url 정리
- 실제 아기의 `photo_url = "data:image/jpeg;base64,/9j/test123"` (가짜 base64).
- **이미 우회됨**: 프론트 `BabyAvatar`가 짧은/깨진 data URL 감지 → 이모지 fallback + onError. 화면 정상.
- 근본 정리: `UPDATE babies SET photo_url=NULL WHERE id='00000000-...02'` (또는 사용자가 설정에서 진짜 사진 업로드 시 자동 해결).

---

## 2. 🟡 보류 — 음성 입력 재설계
- 기존 플로팅 음성 버튼(QuickActionFAB→VoiceMicButton)이 **기록 편집 시트와 겹쳐서 제거**함 (commit 0615975).
- 음성 입력 자체는 유지하고 싶으나 **배치 재설계 필요**. 후보: ① ChatInput/기록 시트 내 마이크 아이콘, ② 홈 BigActionGrid 옆 작은 버튼, ③ 헤더.
- 관련 파일(현재 미마운트, 보존됨): `frontend/src/shared/components/QuickActionFAB.tsx`, `VoiceMicButton.tsx`, `features/recording/components/VoiceCommandHero.tsx`, `shared/hooks/useVoiceCommand.ts`.

---

## 3. UX 멀티에이전트 회의 산출 — 미적용 (P4~P9)
> 상세: `docs/UX_REFACTOR_PLAN.md`. P1~P3(데이터 깜빡임/캐시영속화/세션초기화)는 **적용 완료**.

- **P4 (M)** 성공/에러 피드백 일원화: 모든 mutation onSuccess 토스트, `alert()` 전부 토스트로 통일. 검증 오류도 토스트. (현재 `alert` 잔존: SleepTimer, FeedingForm, PlayForm, ActiveSessionBanner)
- **P5 (L)** Baby 단일 진실소스: babyStore와 React Query 캐시 이중화 정리. GET /babies 후 store+query 동시 갱신 wrapper, `initializeBaby()` 통합(onboarding/login/코드참여 수렴).
- **P6 (M)** 설정 아기정보 수정 원자화: settings가 setName/setPhotoUrl 먼저 호출 후 API patch → 실패 시 store 오염. store 래퍼에서 API 성공 시에만 커밋+롤백.
- **P7 (M)** TimelineScrollView 안정화: pin 유지/스크롤 복원 race. (※ 기본 pin·7일로드는 적용됨. 추가 안정화 미적용.) oldestOffset을 uiStore 보존.
- **P8 (L)** 🎨 **디자인 토큰 도입** (UI 교체 가능성의 핵심): `src/shared/design/tokens.css`에 color/spacing/radius/typography 토큰, Tailwind v4 `@theme`/`@utility` 활용. 도메인색(수유=파랑/모유=분홍/수면=자주)을 `activityColorToken` 맵 한 곳으로 중앙화. button.tsx 등 하드코딩 색 치환. 점진 PR.
- **P9 (L)** 🏛️ **DTO↔UIModel adapter** (클린아키텍처 핵심): RecordEditSheet가 4개 피처 API 직접 import, BigActionGrid 5개 활동 switch. `dateTimeAdapter`/`feedingTypeMapper` 중앙화 → validator 추출 → headless 폼 훅 → activityRegistry. 백엔드 enum 변경이 adapter 한 곳에만 닿게.

**사용자 핵심 의도(반드시 기억):** "UI 디자인은 변경 가능해야 하되, 도메인/엔티티/DB는 불변." → P8·P9가 이 의도의 정수. 디자인 교체 요청이 오면 P8부터.

---

## 4. 배포 플랜 잔여 Stage (운영자 도구) — 미시작
> 상세: `~/.claude/plans/temporal-waddling-bee.md` Stage 6~9.

사용자 요청 ②: **로컬 전용 운영자 도구**로 브랜딩 이미지·기록 타입 이모지/라벨·텍스트를 편집하면 실제 프로덕션 웹에 반영 + 유저 정보 조회(읽기 전용).
- **Stage 6** core에 `AppContentModel`(key/kind/value) 테이블 + 공개 `GET /api/v1/content` + 프론트 `useAppContent()` 훅(하드코딩 fallback).
- **Stage 7** `PUT/GET /internal/admin/content`(X-Internal-Key), `GET /internal/admin/users`(auth)/`/babies`(core) 읽기전용.
- **Stage 8** 프론트 `/admin` 라우트 — `middleware`로 `NEXT_PUBLIC_ADMIN_ENABLED!=="true"`면 404(로컬 전용). 프로덕션 백엔드 URL+INTERNAL_API_KEY를 localStorage 입력.
- **Stage 9** 검증.

---

## 5. 이식 가이드 / 프로덕션 compose — 미작성
사용자 요청: "내가 쓴 걸 다른 사람들이 다 쓰는 것(AWS 등)으로 바꿀 수 있게." 현재 코드는 이미 12-factor+Docker라 **이식 가능**(env만 교체). 남은 작업: `docs/DEPLOYMENT.md`(AWS/VPS 이전 레시피) + `docker-compose.prod.yml`(한 서버에 3개 통합 실행). "배포 후 하기로" 합의됨.

---

## 6. 알려진 정리 대상 (미사용 코드, 빌드엔 무해)
홈 심플화·음성 제거로 **미사용이 된 컴포넌트**(삭제 안 함, 보존):
- `features/baby/components/MilestoneBanner.tsx`
- `features/dashboard/components/NextFeedingCard.tsx`
- `features/recording/components/QuickRepeatRow.tsx` + `hooks/useLastRecord.ts`
- `features/recording/components/VoiceCommandHero.tsx`
- `shared/components/QuickActionFAB.tsx`, `VoiceMicButton.tsx` (음성 재설계 시 재사용 가능)

---

## 7. 사용자 검증 대기 항목 (재배포 후 실기기/실계정 확인 필요)
제가 코드는 다 반영했으나 **실제 화면/기기 확인은 사용자만 가능**:
1. **AI 날짜 연동**(방금 배포): 헤더 6/4 선택 → AI 리뷰 생성 시 `review_date`가 6/4인지 / 채팅이 그날 기록 언급하는지
2. **모바일 하단 잘림**: 사파리/크롬/네이버 인앱 각각 하단 탭바·콘텐츠 다 보이는지
3. **기록 수정 낙관적**: 수정 시 시트 즉시 닫힘 + 타임라인 즉시 반영
4. **초대코드 로그인 유지**: 백그라운드 후 복귀 시 유지
5. **로그인 흐름**: zzippu.co.kr/login 이메일 OTP → 메인 진입

---

## 8. 개발 워크플로 원칙 (사용자 표준, 메모리에도 저장됨)
1. 계획 먼저 → 2. 계획을 .md에 반영하고 끝나면 .md 정리 → 3. 결합도↓ 응집도↑, 클린코드/클린아키텍처.
- 모델 분업: Opus=계획/설계, Sonnet=구현, Haiku=탐색/요약.
- 복잡/중대한 작업은 멀티에이전트 회의(Workflow) 후 진행. 단 **요구가 명확한 작업은 회의 없이 바로** (토큰 효율).
- 커밋·푸시는 작업 단위로. main 자동배포.

## 9. 우선순위 추천 (다음 세션 시작점)
1. **막힌 운영 DB 정리**(테스트 더미 + photo_url) — 사용자 승인 받고 실행
2. **AI 날짜 연동 실제 테스트** (재배포 완료 후)
3. 사용자 선택: 음성 재설계 / P8 디자인토큰 / Stage 6~9 운영자도구 / 이식 가이드
