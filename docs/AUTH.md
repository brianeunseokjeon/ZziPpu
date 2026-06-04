# 인증 (auth-service)

이메일 OTP 기반 패스워드리스 신원 + 약관 동의 + 공동양육자 코드 로그인. JWT 발급은 auth-service 전담.

## 1. 이메일 OTP 흐름

```
[프론트 /login]                 [auth-service :8082]
  이메일 입력 ──POST /api/v1/auth/email/request {email}──▶ OTP 생성·해시·저장·발송 → 204
  코드 입력   ──POST /api/v1/auth/email/verify {email,code}─▶ 검증 → user 조회/생성 → JWT
                                          ◀── { access_token, user_id, is_new_user, terms_required }
  termsRequired? → /terms        아니면 → core GET /babies → 없으면 /onboarding, 있으면 /
```

- 6자리 코드(`secrets`), HMAC-SHA256 해시(`SECRET_KEY` pepper)로 저장 — 평문 미저장.
- TTL 5분, 최대 5회 시도, 검증은 `hmac.compare_digest`(timing-safe).
- baby 는 생성하지 않는다(온보딩에서 `POST /babies`).

## 2. 약관 / 동의

- 약관 본문 = **버전드 마크다운**(`auth-service/app/content/terms/service_terms_v1.md`, `privacy_policy_v1.md`).
  서버 기동 시 `terms` 테이블로 seed(upsert). 파일을 바꾸고 버전을 올리면 교체된다.
- `GET /api/v1/auth/terms` → 활성 약관 목록(type, version, title, content, required).
- `POST /api/v1/auth/terms/agree {agreements:[{type,version}]}` (Bearer 필요) → 204.
- `terms_required` = "활성 **필수** 약관 중 미동의가 하나라도 있으면 true".

> ⚠️ 현재 약관 본문은 **검토용 템플릿**이다. 만 14세 미만 아동 정보·건강 관련 데이터를 다루므로
> 배포 전 반드시 변호사 검토를 받아야 한다.

## 3. 공동양육자 코드 로그인 (이메일 없이 코드만으로)

배우자가 **초대코드(1회용)** 만 입력하면 해당 아기에 접근·기록 가능.

```
[프론트 /login "초대코드로 참여"]      [auth :8082]                  [core :8081]
  코드 입력 ─POST /auth/code/redeem──▶ 이메일 없는 caregiver user 생성
                                       ─POST /internal/caregiver/redeem──▶ 코드 검증·링크·소비
                                       (헤더 X-Internal-Key)        ◀── { baby_id }  (무효 시 400)
                                       무효면 방금 만든 user 폐기 후 에러 전파
                                       성공 시 JWT 발급
                          ◀── { access_token, user_id, baby_id, is_new_user:true, terms_required }
```

- **재로그인 주의**: 1회용 코드라 새 기기에선 같은 코드 재사용 불가. 저장된 토큰으로 세션 유지하고,
  분실 시 초대자가 코드를 재발급한다. (이메일 신원이 없으므로 자체 복구 경로 없음 — 사용자 선택)

## 4. 이메일 provider 교체

`EmailSender` 인터페이스 + factory(`EMAIL_PROVIDER` env)로 추상화.

| `EMAIL_PROVIDER` | 동작 |
|---|---|
| `console` (기본, dev) | 콘솔에 `📧 [DEV EMAIL]` / `🔑 [DEV EMAIL OTP]` 출력 — 실제 발송 안 함 |
| `resend` | `RESEND_API_KEY` 로 Resend API 발송. 발신 도메인 인증 필요 |

다른 provider 추가: `EmailSender` 구현 한 개 + factory 분기만 추가하면 됨(코드 다른 곳 무변경).

## 5. 휴대폰 OTP 재활성화

휴대폰(SMS) OTP 도메인/로직은 비활성 보존되어 있다. 재활성화 절차는
[`auth-service/app/_legacy_phone_otp/README.md`](../auth-service/app/_legacy_phone_otp/README.md) 참고.

## 6. 보안 메모

- 레이트리밋: 이메일별 60초 쿨다운 / 시간당 5회, IP 시간당 20회.
- OTP 코드 평문 미저장(HMAC 해시), timing-safe 비교.
- `SECRET_KEY`, `INTERNAL_API_KEY` 는 운영에서 강한 랜덤값으로 교체하고 두 서비스에 동일 주입.
- JWT 는 클라이언트 localStorage(zustand persist)에 저장 — XSS 방어가 전제. 운영 강화 시 httpOnly 쿠키 고려.
