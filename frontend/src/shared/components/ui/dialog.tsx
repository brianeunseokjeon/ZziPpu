"use client";

/**
 * Dialog (바텀 시트) — createPortal로 document.body에 직접 마운트.
 *
 * WHY portal: layout wrapper가 `overflow-hidden`인 상황에서 iOS Safari는
 * fixed 자식 요소를 클리핑할 수 있다. portal로 body에 직접 붙이면
 * 어떤 overflow/z-index 환경에서도 안전하게 최상위에 렌더링된다.
 */

import * as React from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";

interface DialogProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  className?: string;
}

export function Dialog({ open, onClose, title, children, className }: DialogProps) {
  // SSR 단계에선 document.body 미존재 → 마운트 후에만 portal 활성화
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => { setMounted(true); }, []);

  // 시트 열릴 때 body 스크롤 잠금
  React.useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [open]);

  if (!mounted || !open) return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[999] flex items-end sm:items-center justify-center"
      style={{ WebkitBackfaceVisibility: "hidden" }}
    >
      {/* 반투명 배경 */}
      <div
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* 시트 본체 */}
      <div
        className={cn(
          // max-h에 dvh 사용: iOS Safari 동적 주소창 반영
          // pb-safe: 홈인디케이터/탭바 위로 버튼이 잘리지 않도록
          "relative bg-white rounded-t-3xl sm:rounded-3xl w-full sm:max-w-md",
          "max-h-[90dvh] overflow-y-auto shadow-xl",
          className
        )}
      >
        {/* 헤더 */}
        <div className="flex items-center justify-between p-5 border-b border-gray-100">
          {title && (
            <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
          )}
          <button
            onClick={onClose}
            className="ml-auto p-2 rounded-full hover:bg-gray-100 transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* 콘텐츠 — pb-safe로 하단 safe area 확보 */}
        <div className="p-5 pb-safe">{children}</div>
      </div>
    </div>,
    document.body
  );
}
