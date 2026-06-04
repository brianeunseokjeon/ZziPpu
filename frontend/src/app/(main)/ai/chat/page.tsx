'use client'

import { useEffect, useRef } from 'react'
import { RotateCcw } from 'lucide-react'
import { useUIStore } from '@/shared/stores/uiStore'
import {
  useChat,
  ChatMessageBubble,
  StreamingMessage,
  ChatInput,
  QuickQuestions,
} from '@/features/ai-chat'

export default function AIChatPage() {
  const activeBabyId = useUIStore((s) => s.activeBabyId)
  const { messages, isStreaming, streamingContent, sendMessage, resetChat } =
    useChat(activeBabyId)
  const bottomRef = useRef<HTMLDivElement>(null)

  // 메시지 추가 시 자동 스크롤
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, streamingContent])

  const hasMessages = messages.length > 0

  return (
    <div className="flex flex-col h-[100dvh] bg-gray-50">
      {/* 헤더 */}
      <div className="flex-shrink-0 flex items-center justify-between px-4 py-3 bg-white border-b border-gray-200">
        <div className="flex items-center gap-2">
          <span className="text-xl">🩺</span>
          <div>
            <h1 className="text-base font-semibold text-gray-900">AI 소아과 상담</h1>
            <p className="text-xs text-gray-400">전문 소아과 지식 기반 AI 상담</p>
          </div>
        </div>
        {hasMessages && (
          <button
            onClick={resetChat}
            className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-full px-3 py-1.5 transition-colors"
          >
            <RotateCcw className="w-3 h-3" />
            새 대화
          </button>
        )}
      </div>

      {/* 채팅 메시지 영역 */}
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-4">
        {!hasMessages && !isStreaming ? (
          <QuickQuestions onSelect={sendMessage} />
        ) : (
          <>
            {messages.map((msg) => (
              <ChatMessageBubble key={msg.id} message={msg} />
            ))}
            {isStreaming && <StreamingMessage content={streamingContent} />}
          </>
        )}
        <div ref={bottomRef} />
      </div>

      {/* 채팅 입력창 - 탭바 위 고정 */}
      <div className="flex-shrink-0 pb-20">
        <ChatInput onSend={sendMessage} disabled={isStreaming} />
      </div>
    </div>
  )
}
