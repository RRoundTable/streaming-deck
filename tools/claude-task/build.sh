#!/bin/bash
# 사용: build.sh <작업 이름> "<앱 이름>"
# 예: build.sh daily-scrum "Claude Daily Scrum" → ~/Applications/Claude Daily Scrum.app
set -euo pipefail

task="${1:?작업 이름이 필요합니다}"
name="${2:?앱 이름이 필요합니다}"
here="$(cd "$(dirname "$0")" && pwd)"
app="$HOME/Applications/$name.app"

if [ ! -f "$HOME/.claude/scheduled-tasks/$task/SKILL.md" ]; then
  echo "예약 작업이 없습니다: ~/.claude/scheduled-tasks/$task/SKILL.md" >&2
  exit 1
fi

mkdir -p "$HOME/Applications"
rm -rf "$app"
osacompile -o "$app" "$here/claude-task.applescript"
cp "$here/run.sh" "$app/Contents/Resources/"
printf '%s' "$task" > "$app/Contents/Resources/task.txt"
chmod +x "$app/Contents/Resources/run.sh"
codesign --force --deep --sign - "$app"
echo "built: $app"
