export interface ChatConversation {
  id: string
  baby_id: string
  title: string | null
  created_at: string
  updated_at: string
}

export interface ChatMessage {
  id: string
  conversation_id: string
  role: 'user' | 'assistant'
  content: string
  created_at: string
}

export interface ChatState {
  conversationId: string | null
  messages: ChatMessage[]
  isStreaming: boolean
  streamingContent: string
}
