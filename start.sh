#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/backend"
FRONTEND="$ROOT/frontend"

# ── 색상 ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log()  { echo -e "${CYAN}[먹놀잠]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }

# ── .env 체크 ─────────────────────────────────────────────────────────
if [[ ! -f "$BACKEND/.env" ]]; then
  warn ".env 파일이 없습니다. $BACKEND/.env.example 을 복사해서 설정하세요."
  warn "  cp backend/.env.example backend/.env"
  warn "AI 기능은 ANTHROPIC_API_KEY 없이 동작하지 않습니다."
fi

# ── Python venv ───────────────────────────────────────────────────────
if [[ ! -d "$BACKEND/.venv" ]]; then
  log "Python 가상환경 생성 중..."
  python3 -m venv "$BACKEND/.venv"
  source "$BACKEND/.venv/bin/activate"
  pip install -q fastapi "uvicorn[standard]" sqlalchemy aiosqlite asyncpg alembic pydantic "pydantic[email]" pydantic-settings anthropic "python-jose[cryptography]" "passlib[bcrypt]" httpx sse-starlette
  ok "Python 패키지 설치 완료"
else
  source "$BACKEND/.venv/bin/activate"
fi

# ── Node modules ───────────────────────────────────────────────────────
if [[ ! -d "$FRONTEND/node_modules" ]]; then
  log "npm install 중..."
  npm install --prefix "$FRONTEND" --silent
  ok "Node 패키지 설치 완료"
fi

# ── 기존 프로세스 정리 ────────────────────────────────────────────────
kill_port() {
  local port="$1"
  local pids
  pids=$(lsof -ti tcp:"$port" 2>/dev/null) || true
  if [[ -n "$pids" ]]; then
    warn "포트 $port 점유 프로세스(PID $pids) 강제 종료 중..."
    echo "$pids" | xargs kill -9 2>/dev/null || true
    # 포트가 실제로 해제될 때까지 최대 5초 대기
    local i=0
    while lsof -ti tcp:"$port" &>/dev/null && (( i++ < 10 )); do sleep 0.5; done
    ok "포트 $port 해제 완료"
  fi
}
kill_port 8081
kill_port 3000

# ── 종료 핸들러 ────────────────────────────────────────────────────────
cleanup() {
  log "서버를 종료합니다..."
  kill "$BACKEND_PID" 2>/dev/null || true
  kill "$FRONTEND_PID" 2>/dev/null || true
  wait 2>/dev/null
  ok "종료 완료"
}
trap cleanup EXIT INT TERM

# ── 백엔드 시작 ────────────────────────────────────────────────────────
log "백엔드 서버 시작 중... (http://localhost:8081)"
cd "$BACKEND"
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8081 --reload &
BACKEND_PID=$!

# ── 프론트엔드 시작 ────────────────────────────────────────────────────
log "프론트엔드 서버 시작 중... (http://localhost:3000)"
cd "$FRONTEND"
npm run dev -- --port 3000 &
FRONTEND_PID=$!

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  먹놀잠 서비스가 시작되었습니다 👶${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  프론트엔드: ${CYAN}http://localhost:3000${NC}"
echo -e "  백엔드 API: ${CYAN}http://localhost:8081${NC}"
echo -e "  API 문서:   ${CYAN}http://localhost:8081/docs${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}Ctrl+C${NC} 로 종료"
echo ""

wait
