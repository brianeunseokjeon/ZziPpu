# 휴대폰(SMS) OTP — 비활성 보존

사용자 결정에 따라 **신원 식별자는 이메일 OTP**로 채택했고, 기존 휴대폰 OTP는 **비활성 상태로 보존**한다.
원본 구현(휴대폰 OTP 도메인/유스케이스/SMS 인프라)은 `backend/` 의 git 히스토리에 그대로 남아 있다:

- `backend/app/domain/entities/otp_code.py`
- `backend/app/domain/repositories/otp_repository.py`
- `backend/app/application/use_cases/auth/{request_otp,verify_otp}.py`
- `backend/app/infrastructure/sms/{factory,console_sms,ncp_sens_sms}.py`
- `backend/app/infrastructure/persistence/models/otp_model.py`
- `backend/app/infrastructure/persistence/repositories/otp_repository_impl.py`

auth-service 의 이메일 OTP 구조는 위 패턴을 그대로 이식한 것이므로, 재활성화는 "이메일을 휴대폰으로 바꾸는"
대칭 작업이다.

## 재활성화 방법

1. **도메인/모델**: `EmailOtp`/`EmailOtpModel`(table `email_otp_codes`)을 그대로 복제해
   `PhoneOtp`/`PhoneOtpModel`(table `phone_otp_codes`, `email` → `phone`)을 만든다.
2. **발송 추상화**: `EmailSender` ABC 와 동일한 형태로 `SmsService` ABC(`async send(phone, message)`)와
   `ConsoleSmsService` / `NcpSensSmsService` + factory(`SMS_PROVIDER` env)를 추가한다.
   (원본을 `backend/app/infrastructure/sms/` 에서 그대로 가져오면 된다.)
3. **유스케이스**: `RequestEmailOtpUseCase`/`VerifyEmailOtpUseCase` 를 복제해 `phone` 기반으로 바꾼다.
   `terms_required` 계산·JWT 발급 로직은 동일하게 재사용한다.
4. **라우터**: `POST /auth/phone/request`, `POST /auth/phone/verify` 를 추가하고
   `app/presentation/api/v1/router.py` 에 `include_router` 한다.
5. **가드**: `settings.PHONE_OTP_ENABLED`(기본 `false`)가 `true` 일 때만 라우터를 등록하도록 한다.
6. **config**: `SMS_PROVIDER`, NCP SENS 자격증명 등 SMS 관련 env 를 `app/config.py` 에 추가한다.

이메일 OTP 와 휴대폰 OTP 는 같은 `users` 테이블을 공유할 수 있다(식별자 컬럼만 다름).
필요 시 한 사용자가 이메일·휴대폰 둘 다로 로그인하도록 확장 가능하다.
