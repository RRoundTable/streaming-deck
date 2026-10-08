#!/bin/bash
# gcloud-auth.applescript와 실행 파일들을 묶어 ~/Applications/GCloud Auth.app 을 만든다.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$HOME/Applications/GCloud Auth.app"

mkdir -p "$HOME/Applications"
rm -rf "$app"
osacompile -o "$app" "$here/gcloud-auth.applescript"
cp "$here/login.sh" "$here/drive.applescript" "$here/step.js" "$app/Contents/Resources/"
chmod +x "$app/Contents/Resources/login.sh"
codesign --force --deep --sign - "$app"
echo "built: $app"
