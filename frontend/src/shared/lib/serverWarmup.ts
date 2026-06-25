/**
 * 서버 콜드스타트 선제 회피 (Layer 1).
 *
 * 무료 호스팅(Render)은 15분 무요청 시 sleep → 첫 요청이 30~60초 걸린다.
 * 그 사이 사용자가 "분유 먹음"을 누르면 기록이 느리게 가거나 유실될 수 있다.
 *
 * 해결: 앱을 열거나 포그라운드로 돌아오는 "그 순간" 서버를 미리 깨운다.
 * 사용자가 화면을 둘러보고 기록 버튼을 누를 때쯤이면 서버가 이미 깨어 있다.
 *
 * - 응답을 기다리지 않는다(깨우기가 목적). 실패해도 조용히 무시.
 * - core(기록)·auth(로그인) 둘 다 깨운다. core 가 더 중요.
 */
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8081";
const AUTH_BASE_URL = process.env.NEXT_PUBLIC_AUTH_URL ?? "http://localhost:8082";

// 직전 깨우기로부터 이 시간 안에는 다시 핑하지 않는다(불필요한 중복 호출 방지).
const WARMUP_THROTTLE_MS = 60 * 1000;
let lastWarmupAt = 0;

function pingHealth(baseUrl: string): void {
  // keepalive: 탭이 닫히는 중에도 요청이 전송되도록.
  fetch(`${baseUrl}/health`, { method: "GET", keepalive: true }).catch(() => {
    // 깨우는 게 목적 — 연결을 시도한 것만으로 sleep 해제가 시작된다. 결과는 무시.
  });
}

/** core·auth 서버를 깨운다(스로틀 적용). 로컬 개발에선 사실상 무해. */
export function warmupServers(force = false): void {
  if (typeof window === "undefined") return;
  const now = Date.now();
  if (!force && now - lastWarmupAt < WARMUP_THROTTLE_MS) return;
  lastWarmupAt = now;
  pingHealth(API_BASE_URL);
  pingHealth(AUTH_BASE_URL);
}
