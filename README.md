# streaming-deck

키보드 단축키(나중에 Stream Deck)로 업무 모드를 바꾸고 Obsidian 기록 볼트에 로그를 남긴다. 목표와 설계는 [docs/GOAL.md](docs/GOAL.md), [docs/reference/design.md](docs/reference/design.md).

## 동작

| 키 | 명령 | 하는 일 |
|---|---|---|
| ⌃⌥1 | `bin/sd start-day` | 데일리 노트·오늘 로그 생성 → Google Calendar·Tasks·노트 열기 |
| ⌃⌥2 | `bin/sd deep [완료 조건]` | 선택창(MIT leaf 항목만. 새로 입력하면 로그에만 기록) → 방해금지 → 로그 → Slack·Mail 숨김 → 50분 동안 Discord·KakaoTalk 차단 → 종료 시 방해금지 해제·알림 |
| ⌃⌥3 | `bin/sd deep25 [완료 조건]` | ⌃⌥2와 같고 블록 길이만 25분. 로그는 `deep25`, 진행도에 25분 더함 |
| ⌃⌥0 | `bin/sd shutdown` | 블록 해제·방해금지 해제 → 로그 → 노트 열기 → iTerm2 종료 |
| | `bin/sd status` | 상태 한 줄 (메뉴 막대·HUD가 표시) |

- 키, 메뉴 막대(`🎯 32m`), 화면 오른쪽 아래 HUD(전체 문구), 알림은 Hammerspoon(`hammerspoon/sd.lua`)이 맡는다.
- 방해금지는 단축어 `SD Focus On`/`SD Focus Off`를 `bin/sd`가 부른다.
- 기록 볼트: `~/workspace/personal/record-vault`. 데일리 노트는 `Daily/`, 로그는 `Logs/`(노트에 임베드).

## 새 Mac에 설치

```bash
brew install --cask hammerspoon
git clone git@github.com:RRoundTable/streaming-deck.git && cd streaming-deck && bin/setup
```

그다음 단축어 2개, 권한, 동작 확인은 [docs/reference/setup.md](docs/reference/setup.md). Claude Code에서는 이 저장소를 열고 "streaming-deck 설치해줘"라고 하면 `setup-streaming-deck` skill이 안내한다.
