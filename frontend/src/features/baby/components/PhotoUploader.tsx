"use client";

import { useRef } from "react";
import { Camera } from "lucide-react";

interface PhotoUploaderProps {
  currentUrl: string | null;
  onUpload: (base64: string) => void;
}

/**
 * 이미지를 선택하면 Canvas로 256×256 정사각형 크롭 후 base64로 반환.
 * 모바일에서 capture="user"를 통해 셀카 카메라 바로 열기 지원.
 */
export function PhotoUploader({ currentUrl, onUpload }: PhotoUploaderProps) {
  const inputRef = useRef<HTMLInputElement>(null);

  function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (ev) => {
      const img = new Image();
      img.onload = () => {
        const size = 256;
        const canvas = document.createElement("canvas");
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext("2d")!;

        // 짧은 변 기준으로 정사각형 크롭
        const srcSize = Math.min(img.width, img.height);
        const sx = (img.width - srcSize) / 2;
        const sy = (img.height - srcSize) / 2;
        ctx.drawImage(img, sx, sy, srcSize, srcSize, 0, 0, size, size);

        const base64 = canvas.toDataURL("image/jpeg", 0.8);
        onUpload(base64);
      };
      img.src = ev.target?.result as string;
    };
    reader.readAsDataURL(file);

    // 같은 파일 재선택 허용
    e.target.value = "";
  }

  return (
    <button
      type="button"
      onClick={() => inputRef.current?.click()}
      className="relative group"
      aria-label="아기 사진 변경"
    >
      <div className="w-20 h-20 rounded-full overflow-hidden border-2 border-blue-200 bg-gradient-to-br from-blue-200 to-purple-200 flex items-center justify-center">
        {currentUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={currentUrl} alt="아기 사진" className="w-full h-full object-cover" />
        ) : (
          <span className="text-3xl">👶</span>
        )}
      </div>
      {/* 호버/탭 시 카메라 오버레이 */}
      <div className="absolute inset-0 rounded-full bg-black/30 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
        <Camera className="w-6 h-6 text-white" />
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handleFile}
      />
    </button>
  );
}
