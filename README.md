# 먹놀잠 👶

신생아 육아 기록 + AI 소아과 참고 리뷰 서비스. "내 아이의 먹·놀·잠을 기록하고 다른 기기에서도 본다".

> ⚠️ AI 리뷰는 의료행위·진단이 아닙니다. 응급·이상 징후 시 반드시 의료기관을 방문하세요.

## 토폴로지 (2서비스 MSA)

```
frontend (Next.js 16, :3000)
  ├─ 인증 호출        → auth-service  (NEXT_PUBLIC_AUTH_URL, :8082)
  └─ 그 외 모든 호출  → core-service  (NEXT_PUBLIC_API_URL,  :8081)
```

| 서비스 | 책임 | 포트 | DB |
|---|---|---|---|
| **auth-service** | 이메일 OTP, 사용자(users), 약관·동의, 공동양육자 코드 로그인, **JWT 발급** | 8082 | `auth.db` |
| **core-service** (`backend/`) | 아기·기록·통계·AI·공동양육자 도메인, JWT **검증만** | 8081 | `muknoljam.db` |
| **frontend** | Next.js 앱. `features/auth` 만 auth-service 를 안다 | 3000 | — |

두 서비스의 결합점은 둘뿐: **공유 `SECRET_KEY`(JWT 계약)** 과 **공유 `INTERNAL_API_KEY`(내부 호출)**.
자세한 경계·근거는 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), 인증 흐름은 [`docs/AUTH.md`](docs/AUTH.md) 참고.

## 로컬 실행

### A. 스크립트 (권장)

```bash
cp auth-service/.env.example auth-service/.env
cp backend/.env.example      backend/.env
cp frontend/.env.example     frontend/.env.local
# auth/.env 와 backend/.env 의 SECRET_KEY · INTERNAL_API_KEY 를 같은 값으로 맞춘다.
./start.sh
```

→ frontend `:3000`, core `:8081`, auth `:8082` 동시 기동(자동으로 venv/node_modules 설치).

### B. docker-compose

```bash
# (선택) 루트 .env 에 SECRET_KEY, INTERNAL_API_KEY, ANTHROPIC_API_KEY 등 지정
docker-compose up --build
```

### C. 수동

```bash
# auth-service
cd auth-service && python3 -m venv .venv && .venv/bin/pip install -e . \
  && .venv/bin/uvicorn app.main:app --port 8082 --reload
# core-service
cd backend && python3 -m venv .venv && .venv/bin/pip install -e . \
  && .venv/bin/uvicorn app.main:app --port 8081 --reload
# frontend
cd frontend && npm install && npm run dev
```

## 환경 변수 (요약)

| 변수 | 서비스 | 설명 |
|---|---|---|
| `SECRET_KEY` | auth + core | JWT 서명/검증. **두 서비스 동일값 필수** |
| `INTERNAL_API_KEY` | auth + core | 내부 코드 리딤 호출 보호. **두 서비스 동일값 필수** |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | auth + core | 토큰 만료(분) |
| `EMAIL_PROVIDER` | auth | `console`(dev 기본) / `resend` |
| `RESEND_API_KEY`, `EMAIL_FROM` | auth | Resend 사용 시 |
| `CORE_URL` | auth | core 내부 호출 대상 |
| `ANTHROPIC_API_KEY` | core | AI 리뷰 |
| `DEV_MODE` | auth + core | true 면 core 가 토큰 없이 `DEV_USER_ID` 로 동작 |
| `NEXT_PUBLIC_API_URL` / `NEXT_PUBLIC_AUTH_URL` | frontend | core / auth base URL |
| `NEXT_PUBLIC_REQUIRE_AUTH` | frontend | true 면 비로그인 시 `/login` 강제 |

## 프로덕션 메모

- SQLite → Postgres 전환: `DATABASE_URL` 만 교체(예: `postgresql+asyncpg://...`). 코드 변경 없음.
- JWT 는 현재 HS256(대칭키). 다중 서비스 확장 시 RS256(비대칭키)으로 전환 가능 — `docs/ARCHITECTURE.md` 로드맵 참고.
- 약관 본문(`auth-service/app/content/terms/*.md`)은 **검토용 템플릿이며 배포 전 변호사 검토 필수**.
- `*.db`, `.env` 는 커밋하지 않는다.
