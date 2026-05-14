import { MessageCircle } from "lucide-react";
import { Card, CardContent } from "@/shared/components/ui/card";

export default function AIChatPage() {
  return (
    <div className="space-y-4">
      <Card>
        <CardContent className="pt-6">
          <div className="flex flex-col items-center gap-4 py-8 text-center">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-green-400 to-blue-500 flex items-center justify-center">
              <MessageCircle className="w-8 h-8 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">AI 육아 상담</h2>
              <p className="text-gray-500 text-sm leading-relaxed">
                육아 관련 궁금한 점을 AI에게 직접
                <br />
                물어보세요.
              </p>
            </div>
            <div className="bg-amber-50 border border-amber-200 rounded-2xl px-5 py-3 text-sm text-amber-700 font-medium">
              🚧 Phase 2에서 준비됩니다
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
