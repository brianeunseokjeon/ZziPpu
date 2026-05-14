import { ChatMessage } from '../types/chat'

interface ChatMessageBubbleProps {
  message: ChatMessage
}

function renderContent(content: string) {
  // **text** → <strong>text</strong>, \n → <br>
  const parts = content.split(/(\*\*[^*]+\*\*|\n)/g)
  return parts.map((part, i) => {
    if (part === '\n') {
      return <br key={i} />
    }
    if (part.startsWith('**') && part.endsWith('**')) {
      return <strong key={i}>{part.slice(2, -2)}</strong>
    }
    return <span key={i}>{part}</span>
  })
}

export function ChatMessageBubble({ message }: ChatMessageBubbleProps) {
  const isUser = message.role === 'user'

  if (isUser) {
    return (
      <div className="flex justify-end mb-3">
        <div className="max-w-[75%] bg-blue-500 text-white rounded-2xl rounded-br-sm px-4 py-3 text-sm leading-relaxed shadow-sm">
          {renderContent(message.content)}
        </div>
      </div>
    )
  }

  return (
    <div className="flex items-start gap-2 mb-3">
      <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-base">
        🩺
      </div>
      <div className="max-w-[75%] bg-white text-gray-800 rounded-2xl rounded-bl-sm px-4 py-3 text-sm leading-relaxed shadow-sm">
        {renderContent(message.content)}
      </div>
    </div>
  )
}
