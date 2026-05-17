/**
 * 한국 핸드폰 번호 유틸.
 * - 입력: "010-1234-5678", "01012345678", "+821012345678", "+82 10 1234 5678"
 * - E.164 (백엔드 전송용): "+821012345678"
 * - KR 표시용:           "010-1234-5678"
 */

const DIGITS_ONLY = /^[0-9]+$/;

function digitsOnly(s: string): string {
  return s.replace(/[^0-9]/g, "");
}

/** 사용자 입력 → E.164 (+82...). 유효하지 않으면 throw. */
export function toE164(value: string): string {
  if (!value) throw new Error("핸드폰 번호가 비어 있습니다.");
  const trimmed = value.trim();
  const hasPlus = trimmed.startsWith("+");
  const d = digitsOnly(trimmed);

  if (!DIGITS_ONLY.test(d)) throw new Error("형식이 올바르지 않습니다.");
  if (hasPlus) return "+" + d;
  if (d.startsWith("82")) return "+" + d;
  if (d.startsWith("0")) return "+82" + d.slice(1);
  throw new Error("지원하지 않는 형식입니다.");
}

/** 입력 중 자동 마스킹: 010-1234-5678. 11자리 미만이면 가능한 만큼만. */
export function formatKR(value: string): string {
  const d = digitsOnly(value).slice(0, 11);
  if (d.length <= 3) return d;
  if (d.length <= 7) return `${d.slice(0, 3)}-${d.slice(3)}`;
  return `${d.slice(0, 3)}-${d.slice(3, 7)}-${d.slice(7)}`;
}

/** 11자리 KR 번호인지 검증 (010/011/016/017/018/019로 시작) */
export function isValidKrPhone(value: string): boolean {
  const d = digitsOnly(value);
  return /^01[0-9]\d{7,8}$/.test(d);
}
