import { NextRequest, NextResponse } from "next/server";

/**
 * Next.js Edge Middleware는 localStorage에 접근할 수 없다.
 * 인증 상태는 클라이언트 Zustand에 저장되므로 실제 가드는 클라이언트(`AuthGuard`)에서 한다.
 * 여기서는 정적 자원과 (auth) 그룹을 통과시키는 역할만 한다.
 *
 * 추후 백엔드가 httpOnly 쿠키로 JWT를 발급하면 여기에서 server-side 검증 가능.
 */
export function middleware(req: NextRequest) {
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
