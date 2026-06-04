import { authClient } from "@/lib/api-client";

// authClient = auth-service(:8082) 전용. 앱 나머지는 apiClient(core) 만 사용.
// → 인증 교체 시 features/auth 만 수정하면 됨 (결합도 최소화).

export interface EmailOtpVerifyResult {
  accessToken: string;
  tokenType: string;
  userId: string;
  isNewUser: boolean;
  termsRequired: boolean;
}

export interface CodeRedeemResult {
  accessToken: string;
  tokenType: string;
  userId: string;
  babyId: string;
  isNewUser: boolean;
  termsRequired: boolean;
}

export interface TermDoc {
  type: "service" | "privacy";
  version: string;
  title: string;
  content: string;
  required: boolean;
}

export interface AgreementInput {
  type: string;
  version: string;
}

/** 이메일 OTP 발송 요청. auth-service 는 204 반환(본문 없음). 429 등은 throw 로 전파. */
export async function requestEmailOtp(email: string): Promise<void> {
  await authClient.post<void>("/api/v1/auth/email/request", { email });
}

/** 이메일 OTP 검증 + JWT 발급. baby 는 생성하지 않음(온보딩에서 생성). */
export async function verifyEmailOtp(email: string, code: string): Promise<EmailOtpVerifyResult> {
  return authClient.post<EmailOtpVerifyResult>("/api/v1/auth/email/verify", { email, code });
}

/** 초대코드(1회용)만으로 공동양육자 로그인. 성공 시 baby_id 를 함께 반환. */
export async function redeemInviteCode(code: string): Promise<CodeRedeemResult> {
  return authClient.post<CodeRedeemResult>("/api/v1/auth/code/redeem", { code });
}

/** 활성 약관 목록(이용약관/개인정보). */
export async function getTerms(): Promise<TermDoc[]> {
  return authClient.get<TermDoc[]>("/api/v1/auth/terms");
}

/** 약관 동의 기록. 인증 필요(Bearer). 204 반환. */
export async function agreeTerms(agreements: AgreementInput[]): Promise<void> {
  await authClient.post<void>("/api/v1/auth/terms/agree", { agreements });
}
