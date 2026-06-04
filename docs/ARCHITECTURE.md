# 아키텍처

## 왜 인증만 분리했나

먹놀잠은 커뮤니티가 아니라 "내 아이 기록을 남기고 다른 기기에서도 본다"는 성격이다.
무거운 회원가입은 불필요하고, **OTP로 인증된 이메일 = 가벼운 신원**이면 충분하다.
사용자 요구는 (1) 인증의 결합도를 최소화해 **언제든 교체 가능**할 것, (2) 서버를 **MSA**로 가져갈 것.
→ 가장 교체 압력이 높은 **인증만 별도 서비스로 분리**하고(2서비스), 나머지 도메인은 core 모놀리스로 유지한다.
과도한 분리(아기/기록/AI까지 쪼개기)는 현 규모에 비용만 크므로 의도적으로 하지 않았다.

## 서비스 경계

```
frontend (:3000)
  ├─ features/auth → auth-service (:8082)   이메일 OTP·약관·코드 로그인·JWT 발급
  └─ 그 외         → core-service (:8081)   아기·기록·통계·AI·공동양육자
```

- **auth-service**: `users`, `email_otp_codes`, `terms`, `terms_agreements` 소유. JWT 발급.
- **core-service**: `babies`, 기록 테이블들, `baby_caregivers`, `caregiver_invites` 소유. JWT **검증만**.
- 게이트웨이 없음 — 프론트가 두 base URL 을 직접 사용. `features/auth` 만 `authClient` 를 알기 때문에
  인증 교체 시 영향 범위가 그 폴더로 격리된다.

## 결합점은 둘뿐

### 1. JWT 계약 (인증 신뢰)
- 페이로드: `{ "sub": "<user_id UUID>", "exp": <unix> }`, 알고리즘 **HS256**, 공유 `SECRET_KEY`.
- auth 가 발급, core 는 디코드해서 `user_id` 만 신뢰한다(**DB 조회 안 함**).
- core 의 `babies.user_id` 등은 **불투명 UUID 클레임**으로 취급 — 교차 DB FK 없음.

### 2. 내부 호출 (공동양육자 코드 리딤)
- `POST {CORE_URL}/internal/caregiver/redeem`, 헤더 `X-Internal-Key: <INTERNAL_API_KEY>`, body `{ code, user_id }`.
- 아직 미인증 상태(유저 JWT 없음)에서 호출되므로 유저 토큰이 아니라 **서비스 키**로 보호한다.
- core 가 코드 검증 → `baby_caregivers` 링크 → 코드 소비 → `{ baby_id }` 반환.

## 데이터 소유 분리

- 서비스별 독립 DB(`auth.db` / `muknoljam.db`). 교차 DB 외래키 없음.
- core 는 user 의 이름/이메일을 모른다. 공동양육자 표시 이름이 필요하면 일단 라벨로 폴백,
  후속으로 auth-service `GET /auth/users/{id}` 보강 가능.

## 행동 변경 (모놀리스 대비)

- **자동 아기 생성 제거**: 예전엔 첫 OTP 검증 시 baby 를 자동 생성했다. 이제 생성하지 않고
  온보딩에서 `POST /babies` 로 만든다(경계가 깔끔: auth=신원, core=도메인).
- **휴대폰 OTP 비활성 보존**: 도메인/인프라는 보존하되 라우터 미등록(`auth-service/app/_legacy_phone_otp/` 문서 참고).

## 확장 로드맵

- **Postgres**: `DATABASE_URL` 만 교체. SQLAlchemy async 라 코드 무변경.
- **RS256 전환**: auth 가 private key 로 서명, core 는 public key(JWKS)로 검증 → `SECRET_KEY` 공유 제거.
- **게이트웨이 추가**: 두 base URL 대신 단일 진입점 + 라우팅. 현 경계 위에서 가능.
- **도메인 추가 분리**: AI·통계 등 부하/배포 주기가 다른 영역을 같은 JWT 계약 위에서 분리.
