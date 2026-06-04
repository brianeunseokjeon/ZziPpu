# core-service (`backend/`)

먹놀잠 도메인 서비스 (:8081). 아기·기록·통계·AI·공동양육자. **JWT 는 검증만** 하고 발급하지 않는다.
인증/발급은 auth-service(:8082) 담당.

## 레이어 (클린 아키텍처)

```
app/
  domain/            엔티티 + 리포지토리 ABC (Baby, 기록들, Caregiver, Invite)
  application/       유스케이스 + DTO
  infrastructure/    persistence(SQLAlchemy), auth(jwt 검증), ai(anthropic)
  presentation/      api/v1 라우터, api/internal_router(내부), dependencies, schemas
```

## 인증 모델

- `get_current_user_id`: `DEV_MODE=true` 면 `DEV_USER_ID` 반환(로컬 무토큰 개발), 아니면 Bearer JWT 디코드.
- 토큰의 `sub`(user_id)만 신뢰 — user DB 조회 없음(불투명 UUID 클레임). `SECRET_KEY` 는 auth 와 동일값.
- `UserModel`/`UserRepositoryImpl` 은 휴면 상태로 보존(현재 인증 경로에서 미사용).

## 주요 엔드포인트

| 메서드 | 경로 | 설명 |
|---|---|---|
| POST | `/api/v1/babies` | 아기 생성(온보딩) |
| GET | `/api/v1/babies` | 내 아기 목록 |
| POST | `/internal/caregiver/redeem` | **내부** 코드 리딤(`X-Internal-Key`, 유저 JWT 아님) |
| GET | `/health` | 상태 |

기록(feeding/diaper/sleep/play/growth/vaccination)·AI·공동양육자 라우터는 `/api/v1` 하위에 존재.

## 실행

```bash
cp .env.example .env       # SECRET_KEY · INTERNAL_API_KEY 를 auth 와 동일하게, ANTHROPIC_API_KEY 선택
python3 -m venv .venv && .venv/bin/pip install -e .
.venv/bin/uvicorn app.main:app --port 8081 --reload
```

경계·근거는 [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) 참고.
