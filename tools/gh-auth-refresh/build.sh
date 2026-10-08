#!/bin/bash
# gh-auth-refresh.applescript와 실행 파일들을 묶어 ~/Applications/GH Auth Refresh.app 을 만든다.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$HOME/Applications/GH Auth Refresh.app"

mkdir -p "$HOME/Applications"
rm -rf "$app"
osacompile -o "$app" "$here/gh-auth-refresh.applescript"
cp "$here/refresh.sh" "$here/drive.applescript" "$here/step.js" "$here/scopes.txt" "$app/Contents/Resources/"
chmod +x "$app/Contents/Resources/refresh.sh"
codesign --force --deep --sign - "$app"
echo "built: $app"
