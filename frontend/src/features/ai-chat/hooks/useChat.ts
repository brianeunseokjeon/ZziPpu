'use client'

import { useEffect, useRef } from 'react'
import { API_BASE_URL } from '@/config/constants'
import { useChatStore } from '../store/chatStore'

export function useChat(babyId: string, chatDate: string) {
  const store = useChatStore()
  const resetChat = useChatStore((s) => s.resetChat)

  // 날짜가 바뀌면 대화를 초기화 (날짜별 컨텍스트 오염 방지). 스트리밍 중엔 보류.
  const prevDateRef = useRef(chatDate)
  useEffect(() => {
    if (prevDateRef.current !== chatDate) {
      if (!useChatStore.getState().isStreaming) {
        resetChat()
        prevDateRef.current = chatDate
      }
    }
  }, [chatDate, resetChat])

  const sendMessage = async (message: string) => {
    if (store.isStreaming) return

    // 1. user 메시지를 store에 즉시 추가
    store.addMessage({
      id: `msg-${Date.now()}`,
      conversation_id: store.conversationId ?? '',
      role: 'user',
      content: message,
      created_at: new Date().toISOString(),
    })

    // streaming 상태 시작 (빈 내용으로)
    store.appendStreamChunk('')

    try {
      // 2. fetch로 SSE 스트리밍 시작
      const response = await fetch(
        `${API_BASE_URL}/api/v1/babies/${babyId}/ai/chat`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'text/event-stream',
          },
          body: JSON.stringify({
            message,
            conversation_id: store.conversationId ?? undefined,
            chat_date: chatDate,
          }),
        }
      )

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      if (!response.body) {
        throw new Error('No response body')
      }

      // 3. response.body ReadableStream으로 청크 읽기
      const reader = response.body.getReader()
      const decoder = new TextDecoder()
      let buffer = ''

      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n')
        // 마지막 줄은 불완전할 수 있으므로 buffer에 유지
        buffer = lines.pop() ?? ''

        for (const line of lines) {
          const trimmed = line.trim()
          if (!trimmed.startsWith('data:')) continue

          const jsonStr = trimmed.slice(5).trim()
          if (!jsonStr) continue

          try {
            const parsed = JSON.parse(jsonStr)

            if (parsed.conversation_id && !parsed.done) {
              // 첫 번째 이벤트: conversation_id
              store.setConversationId(parsed.conversation_id)
            } else if (parsed.chunk !== undefined) {
              // 텍스트 청크
              store.appendStreamChunk(parsed.chunk)
            } else if (parsed.done) {
              // 완료
              if (parsed.conversation_id) {
                store.setConversationId(parsed.conversation_id)
              }
              store.finalizeStream()
            }
          } catch {
            // JSON 파싱 에러 무시
          }
        }
      }

      // 스트림이 done 이벤트 없이 종료된 경우 finalizeStream 호출
      const currentState = useChatStore.getState()
      if (currentState.isStreaming) {
        store.finalizeStream()
      }
    } catch (error) {
      console.error('Chat error:', error)
      // 에러 발생 시 에러 메시지를 assistant 메시지로 추가
      store.appendStreamChunk('죄송합니다. 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.')
      store.finalizeStream()
    }
  }

  return { ...store, sendMessage }
}
