'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Sparkles, MessageCircle, BookOpen, PlayCircle } from 'lucide-react';

const AI_TABS = [
  { href: '/ai/review', icon: Sparkles, label: '오늘 리뷰' },
  { href: '/ai/chat', icon: MessageCircle, label: '소아과 상담' },
  { href: '/ai/saved', icon: BookOpen, label: '저장 정보' },
  { href: '/ai/youtube', icon: PlayCircle, label: 'YT 요약' },
];

export default function AILayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <div className="space-y-0">
      <div className="flex gap-1 bg-gray-100 rounded-2xl p-1 mb-4">
        {AI_TABS.map(({ href, icon: Icon, label }) => {
          const isActive = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={`flex-1 flex flex-col items-center gap-0.5 py-2 px-0.5 rounded-xl text-[10px] font-medium transition-all ${
                isActive
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              <Icon className="w-4 h-4" />
              {label}
            </Link>
          );
        })}
      </div>
      {children}
    </div>
  );
}
