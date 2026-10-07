#!/usr/bin/env bash
# Runs the backlog runner over and over until everything is ticked.
#
#   ./implementation/loop.sh [tasks] [--yolo]
#
# One task per Claude Code invocation, so each task gets a clean context and a
# clean commit. Requires the Claude Code CLI:
#   npm install -g @anthropic-ai/claude-code
#
# Driving this from the desktop app instead? You do not need this script:
#   /loop 45m Read and execute implementation/prompts/00-RUNNER-LOOP.md

set -uo pipefail

TASKS="${1:-8}"
YOLO="${2:-}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
# Every task's verify needs Godot; tools/verify.py's own default is another
# machine's path. Keep one already set, otherwise use this machine's.
export GODOT="${GODOT:-C:/Users/Helel/Documents/godot/Godot_v4.7.1-stable_win64_console.exe}"

if ! command -v claude >/dev/null 2>&1; then
  echo "The Claude Code CLI is not on PATH."
  echo "  npm install -g @anthropic-ai/claude-code"
  echo
  echo "Or, from the desktop app:"
  echo "  /loop 45m Read and execute implementation/prompts/00-RUNNER-LOOP.md"
  exit 1
fi

PERM=(--permission-mode acceptEdits)
if [ "$YOLO" = "--yolo" ]; then
  PERM=(--dangerously-skip-permissions)
fi

mkdir -p implementation/logs

echo
echo "HARVEST THE NIGHT - backlog loop"
python tools/task.py stats
echo

for i in $(seq 1 "$TASKS"); do
  NEXT="$(python tools/task.py next)"
  if echo "$NEXT" | grep -q "nothing actionable"; then
    echo "Queue is empty or fully blocked. Stopping."
    echo "$NEXT"
    break
  fi

  LOG="implementation/logs/$(date +%Y%m%d-%H%M%S).log"
  echo "[$i/$TASKS] $NEXT"
  echo "         log: $LOG"

  claude -p "Read and execute implementation/prompts/00-RUNNER-LOOP.md" "${PERM[@]}" 2>&1 | tee "$LOG"
  CODE="${PIPESTATUS[0]}"

  if [ "$CODE" -ne 0 ]; then
    echo "         claude exited $CODE - see the log. Stopping."
    break
  fi

  if grep -l 'Status:\*\* doing' implementation/prompts/*.md >/dev/null 2>&1; then
    echo "         a task is still marked doing; stopping so you can look at it."
    grep -l 'Status:\*\* doing' implementation/prompts/*.md
    break
  fi

  python tools/task.py stats
  [ "$i" -lt "$TASKS" ] && sleep 5
done

echo
python tools/task.py stats
echo "Journal: implementation/PROGRESS.md"
