#!/bin/bash
# gh-auth-refresh.applescript를 ~/Applications/GH Auth Refresh.app 으로 컴파일한다.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$HOME/Applications/GH Auth Refresh.app"

mkdir -p "$HOME/Applications"
rm -rf "$app"
osacompile -o "$app" "$here/gh-auth-refresh.applescript"
echo "built: $app"
