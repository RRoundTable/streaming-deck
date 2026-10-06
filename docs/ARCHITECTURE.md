# Architecture

## System Overview

macOS 앱 계층은 Hammerspoon 하나다(adr/004). 단축키·메뉴 막대·HUD·알림을 맡고, 로직은 전부 `bin/sd`에 있다. 단축어는 집중 모드 on/off 두 개뿐이고 `bin/sd`가 부른다.

```mermaid
flowchart TD
    K[⌃⌥1/2/3/0<br/>Stream Deck Hotkey] --> HS[Hammerspoon<br/>hammerspoon/sd.lua]
    HS -->|start-day, deep, deep25, shutdown| B[bin/sd]
    B --> O[Obsidian 기록 볼트<br/>Daily/ 생성, Logs/ append]
    B --> F[~/.focus/state.json]
    B -->|shortcuts run| FM[단축어 SD Focus On/Off<br/>방해금지]
    B -->|~/.focus/notify| HS
    HS -->|bin/sd status, timer| MB[메뉴 막대 짧게 + HUD 전체 문구·블록 타이머]
    SDP[Stream Deck 플러그인<br/>streamdeck-plugin/] -->|bin/sd status --short| KEY[Stream Deck 키<br/>남은 시간·MIT 진행]
    SDP -->|bin/sd agenda, calendar| CK[Stream Deck 키<br/>다음 미팅·오늘 날짜]
    SDP -->|bin/sd agents| VK[Stream Deck 키<br/>VM 내 차례·실행 중]
    B -->|open| AG[캘린더 읽기 앱<br/>agenda/SDAgenda.app]
    AG -->|~/.focus/agenda.tsv| B
    B -->|ssh sd-vm| VM[원격 VM<br/>claude agents --json]
    VM -->|~/.focus/agents.tsv| B
    F -.later.-> G[Focus Guard 데몬]
```

## Tech Stack

| Layer | Choice | ADR |
|-------|--------|-----|
| 앱 계층 | Hammerspoon (`hammerspoon/sd.lua`): 단축키, 메뉴 막대, HUD, 알림 | adr/004-hammerspoon-single-app |
| 트리거 | Hammerspoon 단축키 ⌃⌥1/2/3/0, Stream Deck은 Hotkey 액션으로 같은 키 | adr/004-hammerspoon-single-app |
| 집중 모드 | 단축어 `SD Focus On`/`SD Focus Off` (`bin/sd`가 `shortcuts run`) | adr/004-hammerspoon-single-app |
| 기록 | Obsidian 기록 볼트 (`~/workspace/personal/record-vault`), 코어 Daily Notes·Templates. 플러그인 없음 | — |
| 상태 | `~/.focus/state.json` | — |
| 스크립트 | `bin/sd` (zsh). 모든 로직 | — |
| 표시 | `bin/sd status` 한 줄을 Hammerspoon이 메뉴 막대(짧게)와 HUD(전체 문구)로 보여준다. 블록 중 HUD는 `bin/sd timer`의 끝나는 시각으로 초 단위 타이머를 그린다 | adr/003-hammerspoon-hud, adr/004 (adr/001 SwiftBar 대체) |
| Stream Deck 표시 | 자체 표시 전용 플러그인(`streamdeck-plugin/`, 공식 SDK). `bin/sd status --short`를 5초마다·`~/.focus` 변경 시 읽어 키 화면을 그린다. 트리거는 여전히 Hotkey | adr/005-streamdeck-display-plugin |
| VM 세션 상태 | `bin/sd agents`가 ssh(`Host sd-vm`) 한 번으로 VM의 `claude agents --json`과 세션별 claude.ai id(`~/.claude/sessions/*.json`의 `bridgeSessionId`)를 읽어 `~/.focus/agents.tsv`에 캐시. Deep 선택창(고르면 그 세션 화면 열기)·Start Day·Shutdown·회의 직전 경고·Stream Deck VM 키가 쓴다 | adr/007-vm-session-status |
| 캘린더 읽기 | Swift 앱 번들 `agenda/SDAgenda.app` (EventKit). macOS 캘린더에 동기화된 오늘 남은 일정을 `~/.focus/agenda.tsv`에 쓰기만 한다. 판단은 `bin/sd agenda` | adr/006-streamdeck-calendar-key |
| Stream Deck 캘린더 키 | 같은 플러그인의 두 번째 액션. `bin/sd agenda` 한 줄을 1분마다 그리고, 누르면 `bin/sd calendar`(Google Calendar 오늘 보기) | adr/006-streamdeck-calendar-key |
| Focus Guard (Later) | Python + launchd + osascript, `claude -p --model haiku` | — |
| Testing | `SD_VAULT`·`HOME`을 임시 디렉터리로 두고 `bin/sd` 실행 후 노트·state 확인 | — |

## Directory Structure

```
streaming-deck/
├── .claude/skills/setup-streaming-deck/  # 새 Mac 설치 절차 (Claude Code skill)
├── agenda/          # 캘린더 읽기 앱 (main.swift, SDAgenda.app/Contents/Info.plist. bin/setup이 swiftc로 빌드)
├── bin/sd           # 모든 동작의 진입점 (start-day, deep, deep25, shutdown, agenda, agents)
├── bin/setup        # 설치: 볼트·상태 폴더·Hammerspoon 설정 (멱등, 덮어쓰기 없음)
├── hammerspoon/sd.lua  # 앱 계층: 단축키, 메뉴 막대, HUD, 알림
├── streamdeck-plugin/  # Stream Deck 표시 전용 플러그인 (TypeScript, npm run build → *.sdPlugin/bin/plugin.js)
├── vault-template/  # 기록 볼트 뼈대 (템플릿, Inbox, Goals, .obsidian 설정)
├── docs/            # GOAL, ROADMAP, SPEC, ARCHITECTURE, reference/design.md
└── README.md
```

단축어 자체는 macOS에 저장되므로 저장소에는 단축어가 호출하는 스크립트, 볼트 템플릿, 설정 절차만 둔다.

## Import Rules

- `state.json`은 `bin/sd`만 쓰고 해석한다. Hammerspoon은 `bin/sd status` 출력과 `~/.focus/notify`만 쓰고 state.json을 직접 읽지 않는다. Stream Deck 플러그인도 `bin/sd status --short` 출력만 읽고, `~/.focus`는 갱신 신호로만 감시한다. Focus Guard는 state.json을 읽기만 한다.
- `~/.focus/agents.tsv`는 `bin/sd`만 쓰고 읽는다. VM에서 세션을 띄우고 정리하는 일은 이 저장소 밖(Desktop 앱·claude.ai/code)이고, `bin/sd`는 읽기만 한다. VM에는 이 저장소의 어떤 것도 설치하지 않는다.
- `~/.focus/agenda.tsv`는 캘린더 읽기 앱만 쓰고 `bin/sd agenda`만 읽는다. 읽기 앱에는 판단을 두지 않는다(오늘 남은 일정을 그대로 내보낸다). 플러그인과 Hammerspoon은 `bin/sd agenda` 출력만 쓴다.

## Key Patterns

- **로그는 파일에 직접 쓴다** (2026-09-26, Advanced URI 대신): 플러그인 의존이 없고, Obsidian이 꺼져 있어도 기록되며, Focus Guard가 같은 경로를 쓸 수 있다. 대가: 노트를 열 때 특정 줄에 커서를 둘 수 없다.
- **로그 파일은 데일리 노트와 분리한다** (adr/002-separate-log-file): `bin/sd`는 `Logs/YYYY-MM-DD.md`에 줄을 덧붙이기만 하고, 데일리 노트는 `## 집중 로그` 아래 `![[Logs/YYYY-MM-DD]]`로 임베드해 보여준다. 사람이 편집하는 파일과 스크립트가 쓰는 파일이 달라 Obsidian 편집 중 동시 쓰기 충돌이 생기지 않는다. `bin/sd`는 데일리 노트를 만들 때만 쓰고, 이후에는 MIT를 읽기만 한다.
- **알림은 Hammerspoon이 띄운다.** 단축키로 부른 명령은 stdout(성공)·stderr(실패)를 알림으로 띄운다. 백그라운드 `_guard`는 `~/.focus/notify`에 문구를 쓰고, Hammerspoon이 `~/.focus`를 감시하다 읽어서 띄운 뒤 지운다(Hammerspoon이 꺼져 있으면 osascript).
- **집중 모드 on/off만 단축어에 남는다.** macOS에 CLI가 없기 때문. `bin/sd`가 완료 조건 검증 후 `SD Focus On`, 블록 종료·Shutdown 때 `SD Focus Off`를 부른다. 블록과 방해금지 시간이 정확히 일치한다.
- **VM 세션은 ssh로 status만 읽는다** (adr/007-vm-session-status): 다른 기계의 세션 상태를 주는 Claude Code CLI가 없어 ssh로 VM의 `claude agents --json`을 읽는다. 세션 쪽에 규칙·hook을 두지 않으려고 `idle`은 모두 리뷰로 본다(끝났는지 말로 물었는지 가르지 않는다). 완결은 내가 정리해 목록에서 사라진 것뿐이다. 45초 안에 다시 불리면 캐시를 쓴다. 대가: 선택창에 요약이 없고 세션 이름만 보인다.
- **캘린더는 macOS 캘린더를 거쳐 읽는다** (adr/006-streamdeck-calendar-key): 회사 Google 계정을 시스템 설정 → 인터넷 계정에 추가하고, 읽기 앱이 EventKit으로 읽는다. 앱 번들로 두는 이유는 캘린더 권한을 부른 쪽(Hammerspoon, Stream Deck)이 아니라 자기 이름으로 받기 위해서다. `bin/sd agenda`가 불릴 때 `open`으로 실행한다(45초 안에 다시 불리면 앞의 결과를 쓴다. 키는 1분마다 부른다). 읽기 앱은 읽을 때마다 `refreshSourcesIfNecessary`로 원격 동기화를 요청한다(3초쯤 걸려 다음 읽기에 반영). `bin/sd calendar`는 동기화를 기다렸다 읽게 해서 키를 누르면 바로 반영된다. 대가: Google에서 바꾼 일정이 1~2분 늦을 수 있다.

## Constraints

- 트리거 계층에는 로직을 두지 않는다. Stream Deck으로 옮길 때 다시 만들 것이 없어야 한다. 플러그인이 키 입력을 받는 것은 캘린더 키뿐이고, 그때도 `bin/sd calendar`를 부르기만 한다.
- 브라우저는 Chrome·Safari·Arc 중 하나 (Firefox는 AppleScript로 URL 조회 불가).
- 데몬 환경에 `ANTHROPIC_API_KEY`를 두지 않는다.
