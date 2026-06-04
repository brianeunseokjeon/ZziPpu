#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTH="$ROOT/auth-service"
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
  warn "core .env 가 없습니다.  cp backend/.env.example backend/.env"
  warn "AI 기능은 ANTHROPIC_API_KEY 없이 동작하지 않습니다."
fi
if [[ ! -f "$AUTH/.env" ]]; then
  warn "auth .env 가 없습니다.  cp auth-service/.env.example auth-service/.env"
fi
warn "SECRET_KEY · INTERNAL_API_KEY 는 두 서비스에서 동일한 값이어야 합니다."

# ── Python venv (core) ────────────────────────────────────────────────
if [[ ! -d "$BACKEND/.venv" ]]; then
  log "core Python 가상환경 생성 중..."
  python3 -m venv "$BACKEND/.venv"
  "$BACKEND/.venv/bin/pip" install -q fastapi "uvicorn[standard]" sqlalchemy aiosqlite asyncpg alembic "pydantic[email]" pydantic-settings anthropic "python-jose[cryptography]" "passlib[bcrypt]" httpx sse-starlette
  ok "core 패키지 설치 완료"
fi

# ── Python venv (auth) ────────────────────────────────────────────────
if [[ ! -d "$AUTH/.venv" ]]; then
  log "auth Python 가상환경 생성 중..."
  python3 -m venv "$AUTH/.venv"
  "$AUTH/.venv/bin/pip" install -q fastapi "uvicorn[standard]" sqlalchemy aiosqlite asyncpg "pydantic[email]" pydantic-settings "python-jose[cryptography]" httpx
  ok "auth 패키지 설치 완료"
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
    local i=0
    while lsof -ti tcp:"$port" &>/dev/null && (( i++ < 10 )); do sleep 0.5; done
    ok "포트 $port 해제 완료"
  fi
}
kill_port 8082
kill_port 8081
kill_port 3000

# ── 종료 핸들러 ────────────────────────────────────────────────────────
cleanup() {
  log "서버를 종료합니다..."
  kill "$AUTH_PID" 2>/dev/null || true
  kill "$BACKEND_PID" 2>/dev/null || true
  kill "$FRONTEND_PID" 2>/dev/null || true
  wait 2>/dev/null
  ok "종료 완료"
}
trap cleanup EXIT INT TERM

# ── auth-service 시작 ─────────────────────────────────────────────────
log "auth-service 시작 중... (http://localhost:8082)"
cd "$AUTH"
"$AUTH/.venv/bin/python" -m uvicorn app.main:app --host 0.0.0.0 --port 8082 --reload &
AUTH_PID=$!

# ── core-service 시작 ─────────────────────────────────────────────────
log "core-service 시작 중... (http://localhost:8081)"
cd "$BACKEND"
"$BACKEND/.venv/bin/python" -m uvicorn app.main:app --host 0.0.0.0 --port 8081 --reload &
BACKEND_PID=$!

# ── 프론트엔드 시작 ────────────────────────────────────────────────────
log "프론트엔드 시작 중... (http://localhost:3000)"
cd "$FRONTEND"
npm run dev -- --port 3000 &
FRONTEND_PID=$!

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  먹놀잠 서비스가 시작되었습니다 👶${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  프론트엔드:   ${CYAN}http://localhost:3000${NC}"
echo -e "  core API:     ${CYAN}http://localhost:8081${NC}  (docs: /docs)"
echo -e "  auth API:     ${CYAN}http://localhost:8082${NC}  (docs: /docs)"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}Ctrl+C${NC} 로 종료"
echo ""

wait
