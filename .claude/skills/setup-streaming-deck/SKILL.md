---
name: setup-streaming-deck
description: 새 MacBook에 streaming-deck 업무 모드 시스템(bin/sd, 기록 볼트, Hammerspoon 단축키·메뉴 막대·HUD, 방해금지 단축어)을 설치하고 동작을 확인한다. "다른 맥에 설치", "새 맥북 세팅", "streaming-deck 이식", "sd 설치" 요청에 사용.
---

# streaming-deck 설치 (새 Mac)

이 저장소를 clone한 Mac에서 실행한다. 자동화 가능한 부분은 `bin/setup`이 하고, macOS가 막아 둔 부분(단축어 생성, 시스템 설정, 권한 허용)은 사용자에게 정확한 값과 함께 안내한다. 상세 설명과 문제 해결은 `docs/reference/setup.md`에 있다. 단계마다 그 문서의 해당 장을 읽고 안내한다.

구조: 앱은 Hammerspoon 하나(`hammerspoon/sd.lua`, adr/004), 로직은 `bin/sd`, 단축어는 방해금지용 `SD Focus On`/`SD Focus Off` 두 개뿐이다.

## 원칙

- 설치·다운로드(brew)는 실행 전에 사용자에게 확인받는다.
- 시스템 설정은 직접 바꾸지 않는다. 경로를 알려주고 사용자가 바꾼다.
- 단축어는 CLI로 만들 수 없다. 사용자가 만들고, `bin/setup`으로 확인한다.
- 기존 볼트·파일은 덮어쓰지 않는다. `bin/setup`은 없는 파일만 복사한다.
- 앱 숨기기·종료 테스트는 사용자의 실제 앱(Slack, 카카오톡 등)에 영향을 주므로, 실행 전에 알린다.

## 1. 사전 확인

```bash
uname -s                                   # Darwin
sw_vers -productVersion                    # 15.x 기준으로 검증됨
git -C <repo> rev-parse --show-toplevel    # 저장소 경로 = REPO
ls /Applications | grep -E "Obsidian|Hammerspoon"
which brew
```

사용자에게 한 번에 묻는다:
1. 기록 볼트 위치. 기본값은 `~/workspace/personal/record-vault`다. Hammerspoon이 부르는 `sd`에는 환경 변수가 전달되지 않으므로, 다른 경로면 `bin/sd`의 `VAULT` 기본값을 바꿔야 한다.
2. 없는 앱(Obsidian, Hammerspoon)을 brew로 설치해도 되는지.

## 2. 앱 설치 (승인 후)

```bash
brew install --cask obsidian    # 없을 때만
brew install --cask hammerspoon # 없을 때만
```

## 3. bin/setup 실행과 Hammerspoon 시작

```bash
<REPO>/bin/setup
open -a /Applications/Hammerspoon.app
```

출력의 ✓/✗/!를 사용자에게 요약한다. `bin/setup`은 `~/.hammerspoon/init.lua`에 `dofile("<REPO>/hammerspoon/sd.lua").start("<REPO>")`를 추가한다. 이미 Hammerspoon이 실행 중이면 앱을 열어 콘솔에서 `hs.reload()`.

사용자가 할 것: Hammerspoon Preferences → Launch Hammerspoon at login. 꺼져 있으면 재부팅 후 단축키가 안 먹는다.

Hammerspoon 모듈이 살아 있는지 확인(파일이 사라지면 동작 중, 사용자에게 "연결 확인" 알림이 뜬다):

```bash
print "Hammerspoon 연결 확인" > ~/.focus/notify.tmp && mv ~/.focus/notify.tmp ~/.focus/notify
sleep 3; ls ~/.focus/notify 2>/dev/null || echo "sd.lua 동작 중"
```

## 4. Obsidian 볼트 등록 (사용자)

Obsidian → 볼트 전환 → "Open folder as vault" → 기록 볼트 폴더. 볼트 이름은 폴더 이름이 되고, `sd`는 폴더 이름으로 `obsidian://open?vault=`를 호출한다.

## 5. 단축어 2개 (사용자)

`docs/reference/setup.md` 3장을 읽고 안내한다. 키보드 단축키는 지정하지 않는다.

| 단축어 | 액션 |
|---|---|
| SD Focus On | 집중 모드 설정: 방해금지 켜기, 끝: 끌 때까지 |
| SD Focus Off | 집중 모드 설정: 방해금지 끄기 |

만들었다고 하면 `bin/setup`을 다시 실행해 "✓ 단축어 SD Focus On/Off"를 확인하고, 첫 호출 권한을 받게 한다:

```bash
shortcuts run "SD Focus On" && sleep 2 && shortcuts run "SD Focus Off"
```

명령이 끝나지 않으면 "계속하겠습니까" 권한 대기다. 알림 → 옵션 → 항상 허용.

## 6. 시스템 설정과 권한 (사용자)

- 시스템 설정 → 제어 센터 → 집중 모드 → 메뉴 막대에서 보기: 활성화될 때
- Hammerspoon 알림 허용, System Events 제어 허용 (첫 사용 시 묻는다)
- 선택: 전용 집중 모드 "딥워크"와 다크 모드 필터 (setup.md 4장)
- Stream Deck 자리 비움 키를 쓸 때(adr/006, adr/009): 시스템 설정 → 인터넷 계정에 Google 계정을 추가하고 캘린더를 켜고, 캘린더 앱 → 설정 → 일반 → 공휴일 캘린더 보기를 켠 뒤, `<REPO>/bin/sd agenda`를 한 번 실행해 SDAgenda의 캘린더 접근을 허용한다. 계정 로그인과 권한 허용은 사용자가 한다. `bin/setup`이 "캘린더 읽기 앱 건너뜀"이라고 하면 `xcode-select --install`이 먼저다.

## 7. 동작 확인

`docs/reference/setup.md` 7장 체크리스트를 사용자와 함께 확인한다. Claude가 직접 확인할 수 있는 것:

```bash
cat ~/.focus/state.json                                          # 블록 상태
cat <볼트>/Logs/$(date +%F).md                                   # 로그 줄 (노트에는 임베드)
/bin/ps -axo command | grep "^/bin/zsh .*sd _guard"             # 블록 감시 프로세스
<REPO>/bin/sd status                                            # 메뉴 막대·HUD에 표시될 문구
<REPO>/bin/sd agenda                                            # Stream Deck 자리 비움 키에 표시될 문구
```

알림, 달 아이콘, 메뉴 막대, HUD처럼 화면에 보이는 것은 Claude가 볼 수 없다(화면 기록·알림 DB 권한 없음). 사용자에게 물어서 확인한다.

## 알려진 문제

setup.md 6장 표를 먼저 본다. 자주 나오는 것:
- ⌃⌥ 키 무반응 → Hammerspoon 미실행
- ⌃⌥ 키 두 번 실행 → ADR-004 이전 SD 단축어(Start Day/Deep 50/Shutdown/Notify)가 남아 있음. 삭제
- "⚠️ 방해금지 On 실패" → SD Focus On 없음 또는 권한 대기
- 달 아이콘 안 보임 → 제어 센터 메뉴 막대 설정
- 테스트용 감시 프로세스를 끌 때 `pkill -f "sd _guard"`처럼 넓게 쓰지 말 것. 실제 블록의 감시까지 꺼진다. started 값까지 넣어 좁힌다.
