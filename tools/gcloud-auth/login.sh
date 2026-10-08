#!/bin/bash
# gcloud auth login --update-adc 를 시작하고 Aside에서 구글 로그인·동의를 대신 진행한다.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

here="$(cd "$(dirname "$0")" && pwd)"
notify() { osascript -e "display notification \"$1\" with title \"gcloud auth\"" >/dev/null; }

account="$(gcloud config get account 2>/dev/null)"
if [ -z "$account" ]; then
  notify "gcloud에 설정된 계정이 없습니다 (gcloud config set account)"
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# gcloud는 TTY 없이도 인증 URL을 stdout으로 내고 localhost 콜백을 기다린다. 브라우저는 우리가 연다.
BROWSER=/usr/bin/true gcloud auth login --update-adc --quiet </dev/null >"$tmp/out" 2>&1 &
gcloud_pid=$!

url=""
for _ in $(seq 40); do
  url="$(grep -oE 'https://accounts.google.com[^ ]+' "$tmp/out" | head -1)"
  [ -n "$url" ] && break
  sleep 0.25
done
if [ -z "$url" ]; then
  kill "$gcloud_pid" 2>/dev/null
  notify "인증 URL을 받지 못했습니다: $(tail -1 "$tmp/out")"
  exit 1
fi

sed "s|__ACCOUNT__|$account|" "$here/step.js" > "$tmp/step.js"
status="$(osascript "$here/drive.applescript" "$tmp/step.js" "$gcloud_pid" "${url}&login_hint=${account}")"

case "$status" in
  gcloud-exited) wait "$gcloud_pid"; rc=$? ;;
  *) kill "$gcloud_pid" 2>/dev/null; rc=1 ;;
esac

if [ "$rc" -eq 0 ]; then
  notify "인증 갱신 완료 ($account)"
else
  notify "인증 갱신 실패 ($status)"
fi
exit "$rc"
