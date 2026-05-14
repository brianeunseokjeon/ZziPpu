interface QuickQuestionsProps {
  onSelect: (q: string) => void
}

const QUICK_QUESTIONS = [
  '수유 간격이 3시간인데 정상인가요?',
  '터미타임은 언제부터 시작하나요?',
  '대변 색이 초록색인데 괜찮나요?',
  '비타민D는 언제 먹이나요?',
  '잠을 너무 많이 자는 것 같아요',
]

export function QuickQuestions({ onSelect }: QuickQuestionsProps) {
  return (
    <div className="flex flex-col items-center gap-4 py-6 px-4">
      <div className="flex flex-col items-center gap-2 text-center">
        <div className="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center text-3xl">
          🩺
        </div>
        <h2 className="text-lg font-semibold text-gray-800">AI 소아과 상담</h2>
        <p className="text-sm text-gray-500 leading-relaxed">
          아이에 대해 궁금한 점을 편하게 물어보세요.
          <br />
          전문 소아과 지식을 바탕으로 답변드립니다.
        </p>
      </div>

      <div className="w-full">
        <p className="text-xs font-medium text-gray-400 mb-2 text-center">자주 묻는 질문</p>
        <div className="flex flex-wrap gap-2 justify-center">
          {QUICK_QUESTIONS.map((q) => (
            <button
              key={q}
              onClick={() => onSelect(q)}
              className="text-sm bg-white border border-gray-200 text-gray-700 rounded-full px-4 py-2 hover:bg-blue-50 hover:border-blue-300 hover:text-blue-700 transition-colors shadow-sm"
            >
              {q}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
