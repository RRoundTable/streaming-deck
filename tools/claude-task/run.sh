#!/bin/bash
# 사용: run.sh <작업 이름>
# Claude 데스크톱 앱의 예약 작업 프롬프트(~/.claude/scheduled-tasks/<이름>/SKILL.md)를 claude -p로 지금 실행한다.
# 결과는 ~/Library/Logs/claude-task/에 남기고, 끝나면 알림을 띄우고 결과 파일을 연다.
set -uo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

task="${1:?작업 이름이 필요합니다}"
prompt_file="$HOME/.claude/scheduled-tasks/$task/SKILL.md"
logs="$HOME/Library/Logs/claude-task"
lock="$logs/$task.lock"
notify() { osascript -e "display notification \"$1\" with title \"Claude: $task\"" >/dev/null; }

if [ ! -f "$prompt_file" ]; then
  notify "프롬프트 파일이 없습니다: $prompt_file"
  exit 1
fi

mkdir -p "$logs"
# 같은 작업을 두 번 눌러도 한 번만 돈다.
if ! mkdir "$lock" 2>/dev/null; then
  notify "이미 실행 중입니다"
  exit 1
fi
trap 'rmdir "$lock"' EXIT

# 맨 앞 --- … --- frontmatter를 떼고 본문만 프롬프트로 쓴다.
prompt="$(awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm' "$prompt_file")"
out="$logs/$task-$(date +%Y%m%d-%H%M%S).md"

notify "시작했습니다"
cd "$HOME"
# 예약 작업처럼 사람 없이 끝까지 가야 하므로 권한 확인을 끈다.
claude -p --permission-mode bypassPermissions "$prompt" </dev/null >"$out" 2>&1
rc=$?

if [ "$rc" -eq 0 ]; then
  notify "완료했습니다"
else
  notify "실패했습니다 (종료 코드 $rc)"
fi
open -t "$out"
exit "$rc"
