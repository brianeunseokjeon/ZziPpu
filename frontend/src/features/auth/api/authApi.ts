import { apiClient } from "@/lib/api-client";

export interface OtpVerifyResult {
  accessToken: string;
  tokenType: string;
  userId: string;
  babyId: string;
  isNewUser: boolean;
}

/**
 * 핸드폰 OTP 발송 요청. 백엔드는 204를 반환하므로 본문 없음.
 * 에러 메시지(429 rate-limit 등)는 throw로 전파.
 */
export async function requestOtp(phoneE164: string): Promise<void> {
  await apiClient.post<void>("/api/v1/auth/otp/request", { phone: phoneE164 });
}

/**
 * OTP 검증 + JWT 발급. 신규 가입이면 isNewUser=true 이며 baby도 자동 생성됨.
 */
export async function verifyOtp(phoneE164: string, code: string): Promise<OtpVerifyResult> {
  return apiClient.post<OtpVerifyResult>("/api/v1/auth/otp/verify", {
    phone: phoneE164,
    code,
  });
}
