interface StreamingMessageProps {
  content: string
}

function renderContent(content: string) {
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

export function StreamingMessage({ content }: StreamingMessageProps) {
  return (
    <div className="flex items-start gap-2 mb-3">
      <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-base">
        🩺
      </div>
      <div className="max-w-[75%] bg-white text-gray-800 rounded-2xl rounded-bl-sm px-4 py-3 text-sm leading-relaxed shadow-sm">
        {content ? (
          <>
            {renderContent(content)}
            <span className="inline-block w-0.5 h-4 bg-blue-500 animate-pulse ml-0.5 align-middle" />
          </>
        ) : (
          <span className="text-gray-400">
            <span className="inline-flex gap-1 items-center">
              <span className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce [animation-delay:0ms]" />
              <span className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce [animation-delay:150ms]" />
              <span className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce [animation-delay:300ms]" />
            </span>
          </span>
        )}
      </div>
    </div>
  )
}
