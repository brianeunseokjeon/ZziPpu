import type { Metadata, Viewport } from "next";
import { QueryProvider } from "@/providers/QueryProvider";
import { Toaster } from "@/shared/components/Toaster";
import "./globals.css";

export const metadata: Metadata = {
  title: "찌뿌둥 - 신생아 육아 기록",
  description: "신생아 수유, 수면, 배변, 터미타임을 간편하게 기록하세요",
};

// viewportFit:'cover' 가 있어야 env(safe-area-inset-*) 가 실제 값을 갖는다.
// (노치/홈인디케이터 영역까지 그려지고 safe-area 로 패딩 확보)
export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko" className="h-full">
      <head>
        {/* iOS Safari 10+: viewport user-scalable=no 무시됨 → JS로 핀치줌 직접 차단 */}
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){
  function pb(e){e.preventDefault();}
  document.addEventListener('gesturestart',pb,{passive:false});
  document.addEventListener('gesturechange',pb,{passive:false});
  document.addEventListener('gestureend',pb,{passive:false});
  document.addEventListener('touchmove',function(e){if(e.touches.length>1)e.preventDefault();},{passive:false});
})();`,
          }}
        />
      </head>
      <body className="min-h-full bg-gray-50 antialiased">
        <QueryProvider>{children}</QueryProvider>
        <Toaster />
      </body>
    </html>
  );
}
