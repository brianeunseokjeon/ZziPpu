# auth-service

먹놀잠 인증 서비스 (:8082). 이메일 OTP 신원, 약관·동의, 공동양육자 코드 로그인, **JWT 발급**.
core-service 와의 결합점은 공유 `SECRET_KEY`(JWT) 와 `INTERNAL_API_KEY`(내부 호출) 둘뿐.

## 레이어 (클린 아키텍처)

```
app/
  domain/            엔티티 + 리포지토리 ABC (EmailOtp, User, Term, TermsAgreement)
  application/       유스케이스 + 포트(interfaces): EmailSender, TermsChecker, CaregiverRedeemClient
  infrastructure/    persistence(SQLAlchemy), auth(jwt), email(console/resend + factory),
                     terms(seed/checker), core_client(내부 HTTP)
  presentation/      api/v1 라우터, dependencies(DI), schemas, middleware
  content/terms/     버전드 약관 마크다운 (seed 원본)
  _legacy_phone_otp/ 휴대폰 OTP 재활성화 안내(비활성 보존)
```

## 엔드포인트

| 메서드 | 경로 | 설명 |
|---|---|---|
| POST | `/api/v1/auth/email/request` | OTP 발송 → 204 (429 rate-limit) |
| POST | `/api/v1/auth/email/verify` | OTP 검증 → JWT + `terms_required` |
| POST | `/api/v1/auth/code/redeem` | 초대코드 로그인 → JWT + `baby_id` |
| GET | `/api/v1/auth/terms` | 활성 약관 목록 |
| POST | `/api/v1/auth/terms/agree` | 약관 동의(Bearer) → 204 |
| GET | `/health` | `{status:ok, service:auth}` |

## 실행

```bash
cp .env.example .env       # SECRET_KEY · INTERNAL_API_KEY 를 core 와 동일하게
python3 -m venv .venv && .venv/bin/pip install -e .
.venv/bin/uvicorn app.main:app --port 8082 --reload
```

기동 시 `create_all` + 약관 seed 가 자동 실행된다. dev 기본 `EMAIL_PROVIDER=console`(콘솔에 OTP 출력).

자세한 흐름·교체법은 [`../docs/AUTH.md`](../docs/AUTH.md) 참고.
