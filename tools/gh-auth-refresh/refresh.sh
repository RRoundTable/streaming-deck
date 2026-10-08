#!/bin/bash
# gh auth refresh를 시작하고 Aside에서 기기 인증(코드 입력·승인)을 대신 진행한다.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

here="$(cd "$(dirname "$0")" && pwd)"
notify() { osascript -e "display notification \"$1\" with title \"gh auth refresh\"" >/dev/null; }

scopes="$(grep -v '^#' "$here/scopes.txt" | tr -d ' \t' | grep -v '^$' | paste -sd, -)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# gh는 TTY 없이도 코드를 stderr로 내고 승인을 기다린다. 브라우저는 우리가 연다.
GH_BROWSER=/usr/bin/true gh auth refresh -h github.com -s "$scopes" </dev/null 2>"$tmp/err" &
gh_pid=$!

code=""
for _ in $(seq 40); do
  code="$(grep -oE '[0-9A-F]{4}-[0-9A-F]{4}' "$tmp/err" | head -1)"
  [ -n "$code" ] && break
  sleep 0.25
done
if [ -z "$code" ]; then
  kill "$gh_pid" 2>/dev/null
  notify "일회용 코드를 받지 못했습니다: $(tail -1 "$tmp/err")"
  exit 1
fi

sed "s/__CODE__/$code/" "$here/step.js" > "$tmp/step.js"
status="$(osascript "$here/drive.applescript" "$tmp/step.js" "$gh_pid")"

case "$status" in
  success|gh-exited) wait "$gh_pid"; rc=$? ;;
  *) kill "$gh_pid" 2>/dev/null; rc=1 ;;
esac

if [ "$rc" -eq 0 ]; then
  notify "인증 갱신 완료"
else
  notify "인증 갱신 실패 ($status)"
fi
exit "$rc"
