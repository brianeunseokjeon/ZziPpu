import { create } from 'zustand'
import { ChatMessage } from '../types/chat'

interface ChatStore {
  conversationId: string | null
  messages: ChatMessage[]
  isStreaming: boolean
  streamingContent: string
  setConversationId: (id: string) => void
  addMessage: (msg: ChatMessage) => void
  appendStreamChunk: (chunk: string) => void
  finalizeStream: () => void
  resetChat: () => void
}

export const useChatStore = create<ChatStore>((set, get) => ({
  conversationId: null,
  messages: [],
  isStreaming: false,
  streamingContent: '',

  setConversationId: (id: string) => set({ conversationId: id }),

  addMessage: (msg: ChatMessage) =>
    set((state) => ({ messages: [...state.messages, msg] })),

  appendStreamChunk: (chunk: string) =>
    set((state) => ({
      isStreaming: true,
      streamingContent: state.streamingContent + chunk,
    })),

  finalizeStream: () => {
    const { conversationId, streamingContent, messages } = get()
    if (!streamingContent) {
      set({ isStreaming: false, streamingContent: '' })
      return
    }
    const assistantMsg: ChatMessage = {
      id: `msg-${Date.now()}`,
      conversation_id: conversationId ?? '',
      role: 'assistant',
      content: streamingContent,
      created_at: new Date().toISOString(),
    }
    set({
      messages: [...messages, assistantMsg],
      isStreaming: false,
      streamingContent: '',
    })
  },

  resetChat: () =>
    set({
      conversationId: null,
      messages: [],
      isStreaming: false,
      streamingContent: '',
    }),
}))
