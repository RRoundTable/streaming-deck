#!/bin/bash
# 로컬과 agent-sandbox의 gcloud 로그인(--update-adc)을 차례로 갱신한다. 구글 로그인·동의는 Aside에서 대신 진행한다.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

here="$(cd "$(dirname "$0")" && pwd)"
vm=agent-sandbox
notify() { osascript -e "display notification \"$1\" with title \"gcloud auth\"" >/dev/null; }

account="$(gcloud config get account 2>/dev/null)"
if [ -z "$account" ]; then
  notify "gcloud에 설정된 계정이 없습니다 (gcloud config set account)"
  exit 1
fi

tmp="$(mktemp -d)"
trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$tmp"' EXIT

sed "s|__ACCOUNT__|$account|" "$here/step.js" > "$tmp/step.js"

# 프로세스가 파일에 쌓는 출력에서 패턴이 나올 때까지 기다린다. 프로세스가 죽거나 시간이 다 되면 실패한다.
wait_for() { # <파일> <정규식> <PID> <초>
  for _ in $(seq $(($4 * 4))); do
    grep -qE "$2" "$1" && return 0
    kill -0 "$3" 2>/dev/null || return 1
    sleep 0.25
  done
  return 1
}

# Aside에서 인증 URL을 진행한다. 인증을 기다리는 gcloud가 끝나면 gcloud-exited, 아니면 실패 사유를 돌려준다.
drive() { # <gcloud PID> <인증 URL>
  osascript "$here/drive.applescript" "$tmp/step.js" "$1" "$2&login_hint=$account"
}

# gcloud는 TTY 없이도 인증 URL을 stdout으로 내고 localhost 콜백을 기다린다. 브라우저는 우리가 연다.
login_local() {
  BROWSER=/usr/bin/true gcloud auth login --update-adc --quiet </dev/null >"$tmp/local.out" 2>&1 &
  local pid=$!
  if ! wait_for "$tmp/local.out" 'https://accounts.google.com' "$pid" 10; then
    kill "$pid" 2>/dev/null
    echo "인증 URL을 받지 못했습니다: $(tail -1 "$tmp/local.out")"
    return 1
  fi
  local status
  status="$(drive "$pid" "$(grep -oE 'https://accounts.google.com[^ ]+' "$tmp/local.out" | head -1)")"
  [ "$status" = gcloud-exited ] && wait "$pid" && return 0
  kill "$pid" 2>/dev/null
  echo "$status"
  return 1
}

# VM에는 브라우저가 없다. VM이 --no-browser로 내놓는 --remote-bootstrap 명령을 로컬에서 실행해 구글 인증을 끝내고,
# 로컬이 내놓는 localhost 주소 한 줄을 VM 프롬프트에 되돌려 준다. 이 길은 로컬 gcloud 자격(IAP 터널)이 살아 있어야 한다.
login_sandbox() {
  mkfifo "$tmp/vm.in"
  exec 3<>"$tmp/vm.in"
  ssh -o BatchMode=yes -o ConnectTimeout=30 -o ServerAliveInterval=30 "$vm" \
    'gcloud auth login --no-browser --update-adc --quiet' <"$tmp/vm.in" >"$tmp/vm.out" 2>&1 &
  local vm_pid=$!
  if ! wait_for "$tmp/vm.out" 'remote-bootstrap=' "$vm_pid" 40; then
    kill "$vm_pid" 2>/dev/null
    echo "VM에서 인증 명령을 받지 못했습니다: $(tail -1 "$tmp/vm.out")"
    return 1
  fi

  # 이 명령은 신뢰 확인을 묻는다. VM이 방금 낸 명령이므로 y로 답한다.
  local bootstrap
  bootstrap="$(grep -oE 'remote-bootstrap="[^"]+"' "$tmp/vm.out" | head -1 | sed -E 's/^remote-bootstrap="//; s/"$//')"
  BROWSER=/usr/bin/true gcloud auth login --remote-bootstrap="$bootstrap" <<<y >"$tmp/bootstrap.out" 2>&1 &
  local boot_pid=$!
  if ! wait_for "$tmp/bootstrap.out" 'https://accounts.google.com' "$boot_pid" 10; then
    kill "$boot_pid" "$vm_pid" 2>/dev/null
    echo "로컬 인증 URL을 받지 못했습니다: $(tail -1 "$tmp/bootstrap.out")"
    return 1
  fi
  local status
  status="$(drive "$boot_pid" "$(grep -oE 'https://accounts.google.com[^ ]+' "$tmp/bootstrap.out" | head -1)")"
  if [ "$status" != gcloud-exited ] || ! wait "$boot_pid"; then
    kill "$boot_pid" "$vm_pid" 2>/dev/null
    echo "$status"
    return 1
  fi

  grep -oE 'https://localhost[^ ]+' "$tmp/bootstrap.out" | tail -1 >&3
  exec 3>&-
  wait "$vm_pid" || { echo "VM 로그인 실패: $(tail -1 "$tmp/vm.out")"; return 1; }
}

if ! reason="$(login_local)"; then
  notify "로컬 인증 갱신 실패 ($reason)"
  exit 1
fi
if ! reason="$(login_sandbox)"; then
  notify "로컬은 갱신됐지만 sandbox 인증 갱신 실패 ($reason)"
  exit 1
fi
notify "인증 갱신 완료: 로컬·sandbox ($account)"
