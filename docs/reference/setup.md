# 설정 가이드 (Stream Deck 없이 키보드 단축키로)

2026-09-27 기준. macOS 15, Hammerspoon 1.1.

## 1. 구조

앱은 Hammerspoon 하나다(adr/004). 로직은 전부 `bin/sd`에 있고, Hammerspoon은 연결만 한다.

| 계층 | 담당 | 저장 위치 |
|---|---|---|
| Hammerspoon (`hammerspoon/sd.lua`) | ⌃⌥1/2/3/0 단축키, 메뉴 막대, 화면 구석 HUD, 알림 | 저장소 (init.lua가 불러옴) |
| `bin/sd` | 데일리 노트 생성, 집중 로그, 선택창 후보(`sd tasks`), `~/.focus/state.json`, 앱 숨기기·종료, 블록 중 앱 차단, 방해금지 on/off 호출, 상태 문구 | 저장소 |
| 단축어 `SD Focus On`/`SD Focus Off` | 방해금지 켜기·끄기 (macOS에 CLI가 없어서) | macOS |
| 캘린더 읽기 앱 `agenda/SDAgenda.app` | macOS 캘린더의 오늘 남은 일정을 `~/.focus/agenda.tsv`에 쓴다 (adr/006) | 저장소 (`bin/setup`이 빌드) |

```
⌃⌥2 → Hammerspoon → bin/sd deep
                      ├─ (Hammerspoon 선택창: bin/sd tasks 후보, Esc면 여기서 끝, 방해금지도 안 켜짐)
                      ├─ shortcuts run "SD Focus On"
                      ├─ Logs/에 start 줄, state.json, 앱 정리
                      └─ 50분 감시 시작 ── 끝나면 SD Focus Off, end 줄, 알림
     ← stdout "Deep 50 시작 ~HH:MM — …" → Hammerspoon 알림
```

### 알림 경로

| 상황 | 경로 |
|---|---|
| ⌃⌥1·⌃⌥2·⌃⌥3·⌃⌥0 직후 | `bin/sd`의 stdout(성공)·stderr(실패)를 Hammerspoon이 알림으로 |
| 블록 중 앱 차단, 50분 경과 | 감시 프로세스가 `~/.focus/notify`에 쓴다 → Hammerspoon이 읽어서 알림 후 삭제 |

Hammerspoon이 꺼져 있으면 감시 프로세스는 osascript로 알린다(스크립트 편집기 알림이 꺼져 있으면 안 보임).

## 2. 사전 준비 (1회)

1. `brew install --cask hammerspoon` → `bin/setup` → Hammerspoon 실행
   - Hammerspoon Preferences → **Launch Hammerspoon at login** 켜기 (꺼져 있으면 단축키가 안 먹는다)
   - 처음 알림을 띄울 때 Hammerspoon 알림 허용을 묻는다 → 허용
2. 시스템 설정 → 제어 센터 → 집중 모드 → 메뉴 막대에서 보기: **활성화될 때**
   - 기본값이 "표시 안 함"이면 방해금지가 켜져도 달 아이콘이 안 보인다.
3. 기록 볼트 `~/workspace/personal/record-vault`를 Obsidian에서 "Open folder as vault"로 연다.

## 3. 단축어 2개 (방해금지 전용)

각각 액션 하나다. 키보드 단축키는 지정하지 않는다(키는 Hammerspoon이 받는다).

```
SD Focus On:   [집중 모드 설정: 방해금지 켜기, 끝: 끌 때까지]
SD Focus Off:  [집중 모드 설정: 방해금지 끄기]
```

1. 단축어 앱에서 ⌘N → 이름을 정확히 `SD Focus On` / `SD Focus Off`
2. 오른쪽 검색창에서 `집중 모드 설정`을 끌어와 켜기/끄기를 고른다.
3. 테스트: `shortcuts run "SD Focus On"` → 달 아이콘 → `shortcuts run "SD Focus Off"`
   - 처음 실행 시 "계속하겠습니까" 알림이 뜨고 명령이 멈추면 옵션 → **항상 허용**

ADR-004 이전에 만든 `SD Start Day`, `SD Deep 50`, `SD Shutdown`, `SD Notify`는 삭제한다. ⌃⌥ 키가 Hammerspoon과 겹쳐 두 번 실행된다. `bin/setup`이 남아 있으면 알려준다.

## 4. 상태 표시 (메뉴 막대 + HUD)

`bin/sd status`가 상태 한 줄을 만든다. Hammerspoon이 메뉴 막대에는 ` · ` 앞부분만, 화면 오른쪽 아래 HUD에는 전체 문구를 항상 위에 보여준다. 20초마다, 그리고 `~/.focus`가 바뀔 때마다 갱신한다. 딥 블록 중 HUD는 `bin/sd timer`로 끝나는 시각을 받아 1초마다 다시 그린다.

| 상태 | 메뉴 막대 | HUD (전체 문구) |
|---|---|---|
| Start Day 전, Shutdown 후, 날짜가 바뀜 | 없음 | 없음 |
| Start Day 이후, 블록 사이 | `📌 1/6` | `📌 1/6 · 다음 MIT` (체크한 MIT 수 / 전체 MIT 수 + 다음 미완료 항목), 회색 |
| 딥 블록 중 | `🎯 32m` (빨강) | 줄어드는 링 + `32:15` + 완료 조건, 빨강 |
| 블록 종료 후 10분 | `⏰ 블록 종료` | `⏰ 블록 종료 · 집중도를 기록하고 쉬세요` → 이후 `📌` |

- 메뉴 막대를 클릭하면 HUD가 꺼지고 켜진다(꺼 두어도 블록을 시작하면 다시 켜진다). HUD를 끌지 않고 클릭하면 접히고 펴진다: 접으면 블록 중에는 링 + 남은 시간만, 그 밖에는 `📌 1/6`만 남는다. 전체 문구는 메뉴 막대에 포인터를 올리면 보인다.
- MIT는 체크박스로 적는다: `- [ ] 메모리 모듈 설계 [100m]`. Obsidian에서 체크하면 `📌`의 완료 수가 오른다(최대 20초 뒤). 줄 끝의 목표 분은 선택이고 Deep 선택창의 작업별 진행에만 쓴다. 예전 표기 `[2]`는 100분으로 읽는다. Deep 선택창에는 미완료 MIT의 leaf 항목(하위 항목이 없는 것)만 나온다. 하위 항목이 있는 상위 항목은 목록에서 빠진다. 목표는 빠지고 `완료 75/100m`처럼 작업별 진행이 붙는다.
- 선택창에서 목록에 없는 작업을 입력하면 `＋ 새 작업`으로 시작된다. 노트 MIT에는 쓰지 않고 로그의 `start` 줄로만 남는다. 선택창에 다시 나오게 하려면 노트 MIT에 직접 적는다.
- HUD는 반투명이다. 끌면 옮겨지고, 오른쪽 아래 모서리를 끌면 크기가 바뀐다. 포인터를 올리면 그 모서리에 사선 손잡이가 보이고, 모서리 위에서는 진해진다. 위치와 크기는 Hammerspoon 설정(`hs.settings`)에 남는다. 처음 상태로 돌리려면 콘솔에서 `hs.settings.clear("streamingDeck.hudPos"); hs.settings.clear("streamingDeck.hudScale"); hs.reload()`.
- 기본 위치·투명도·색·갱신 주기·단축키는 `hammerspoon/sd.lua` 상단 상수. 바꾼 뒤 Hammerspoon 앱을 열어 콘솔에서 `hs.reload()`.
- Hammerspoon 자체 메뉴 막대 아이콘은 노치 옆 공간을 아끼려고 숨긴다.
- 메뉴 막대 항목이 안 보이면 노치 옆 공간 부족이다. ⌘+드래그로 안 쓰는 아이콘을 빼서 자리를 만든다. HUD는 영향을 받지 않는다.
- 블록 표시를 더 강하게 하려면 전용 집중 모드 "딥워크"를 만들고 집중 모드 필터 → 외관 설정 → 다크 모드를 켠다. `SD Focus On`/`Off`의 집중 모드를 `딥워크`로 바꾼다.

### Stream Deck 버튼 (MK.2, Elgato 앱)

로직은 그대로 `bin/sd`·Hammerspoon에 두고, Elgato 앱 버튼은 같은 키를 보내거나 상태를 읽기만 한다.

| 버튼 | Elgato 액션 | 값 |
|---|---|---|
| Start Day / Deep 50 / Deep 25 / Shutdown | System → Hotkey | ⌃⌥1 / ⌃⌥2 / ⌃⌥3 / ⌃⌥0 |
| 기록 볼트 / round-vault | System → Website (GET request in background 끔) | `obsidian://open?vault=record-vault` / `obsidian://open?vault=round-vault` |
| 남은 시간 | streaming-deck → 남은 시간 (자체 플러그인, `bin/setup`이 설치) | 설정 없음 |
| 캘린더 | streaming-deck → 캘린더 (같은 플러그인) | 설정 없음 |
| VM 세션 | streaming-deck → VM 세션 (같은 플러그인, 8장) | 설정 없음 |

남은 시간 키: 블록 중 빨강 `DEEP 32m`, 종료 후 빨강 `휴식`, 블록 사이 회색 `MIT 1 /6`, Start Day 전·Shutdown 후 어두운 `sd`. 플러그인이 `bin/sd status --short`를 5초마다, `~/.focus`가 바뀔 때 바로 읽는다. 키를 누르면 즉시 새로고침. 메뉴 막대와 같은 `sd status`를 읽으므로 블록 시간과 어긋나지 않는다.

캘린더 키: 진행 중이면 초록 `지금` + 끝나는 시각, 50분 이내에 시작하면 주황 `42m`(Deep 50이 안 들어감), 그보다 뒤면 파랑 `14:00`, 오늘 남은 미팅이 없으면 어두운 바탕에 날짜. 아랫줄은 제목이다. 누르면 Google Calendar 오늘 보기가 열린다. 플러그인이 `bin/sd agenda`를 1분마다 읽고, `sd`는 그때마다 캘린더 읽기 앱을 다시 돌린다.

VM 세션 키: 질문·리뷰할 세션이 있으면 보라 `내 차례 2` + 먼저 볼 세션 이름, 모두 일하는 중이면 초록 `실행 중 3`, 실행 중인 세션이 없으면 주황 `VM 쉬는 중 0`(기획을 넘길 때), VM을 못 읽으면 회색 `?`. 플러그인이 `bin/sd agents`를 1분마다 읽는다. 누르면 claude.ai 세션 목록이 열린다. 캘린더 키가 `⏳`일 때 실행 중인 세션이 0이면 회의마다 한 번 알림이 뜬다.

캘린더 키 준비(1회): 시스템 설정 → 인터넷 계정 → 계정 추가 → Google에서 일정이 있는 계정을 넣고 "캘린더"를 켠다. 캘린더 앱에 일정이 보이면 터미널에서 `bin/sd agenda`를 한 번 실행해 권한 창을 허용한다. Google에서 바꾼 일정은 1~2분 안에 키에 반영된다(읽을 때마다 macOS에 동기화를 요청한다). 바로 보려면 키를 누른다: 동기화 후 4초쯤 뒤에 갱신된다.

플러그인 코드를 고친 뒤: `cd streamdeck-plugin && npm run build && npx streamdeck restart com.rroundtable.sd`. `restart`가 "Restarted"라고 나와도 플러그인이 그대로면 개발자 모드가 꺼진 것이다: `npx streamdeck dev`. 처음 링크한 뒤에는 Stream Deck 앱을 한 번 재시작해야 목록에 나온다. 로그: `streamdeck-plugin/com.rroundtable.sd.sdPlugin/logs/`.

## 5. 첫 실행 권한

| 요청 | 언제 | 선택 |
|---|---|---|
| Hammerspoon 알림 | 첫 알림 | 허용 |
| Hammerspoon이 System Events 제어 | 앱 숨기기 처음 사용 | 허용 |
| "계속하겠습니까" (알림 형태) | `SD Focus On/Off` 첫 호출 | 옵션 → 항상 허용 |
| SDAgenda가 캘린더에 접근 | `bin/sd agenda` 첫 호출, 읽기 앱을 다시 빌드한 뒤 | 전체 접근 허용 |

## 6. 문제 해결

| 증상 | 원인 | 해결 |
|---|---|---|
| ⌃⌥ 키를 눌러도 반응 없음 | Hammerspoon 미실행 | `open -a /Applications/Hammerspoon.app`, 로그인 시 자동 실행 |
| ⌃⌥ 키가 두 번 실행됨 | 예전 SD 단축어의 키가 남아 있음 | 3장 마지막 문단: 예전 단축어 삭제 |
| "⚠️ 방해금지 On 실패" 알림 | `SD Focus On` 단축어가 없거나 권한 대기 | 3장 |
| 방해금지 달 아이콘이 안 보임 | 제어 센터에서 집중 모드 메뉴 막대 표시가 꺼져 있음 | 2장의 2번 |
| "집중 모드"로 표시됨 | macOS 12부터 방해금지는 집중 모드 안의 한 모드 | 정상 |
| `shortcuts run`이 끝나지 않음 | "계속하겠습니까" 권한 확인 대기 | 알림 → 옵션 → 항상 허용 |
| 완료 조건 한글이 `ㄴㅗㅌㅡ`처럼 저장됨 | osascript 입력창에서 한글 IME 조합 실패 (간헐적) | 단축키는 Hammerspoon 선택창을 쓴다. osascript 입력창은 터미널에서 `sd deep`을 인자 없이 부를 때만 뜬다 |
| 로그 줄이 `D@@`처럼 깨짐 | 노트 편집 중 sd가 같은 파일에 써서 Obsidian 병합 충돌 | 로그를 `Logs/`로 분리 (adr/002) |
| 블록 중 카톡·Discord가 다시 켜짐 | 숨김은 ⌘Tab으로 되돌릴 수 있음 | `BLOCKED_APPS`가 블록 동안 5초마다 종료 |
| 캘린더 키에 `?` `캘린더 권한 없음` | SDAgenda의 캘린더 권한이 거부됨 | 시스템 설정 → 개인정보 보호 및 보안 → 캘린더 → SDAgenda 전체 접근 |
| 캘린더 키에 `?` `읽기 앱 없음` | `agenda/SDAgenda.app`이 빌드되지 않음 | `xcode-select --install` 후 `bin/setup` |
| 캘린더 키가 `미팅 없음`인데 일정이 있음 | 계정이 macOS 캘린더에 없거나 아직 동기화 전 | 캘린더 앱에서 일정이 보이는지 확인. 종일·거절한 일정은 원래 안 나온다 |
| Start Day·Shutdown·VM 키에 `VM 연결 안 됨` | `Host sd-vm`이 없거나 키 인증이 안 됨, VM 꺼짐 | 8장 1번. `ssh -o BatchMode=yes sd-vm true`가 바로 끝나야 한다 |
| `VM claude agents 실패` | VM의 로그인 셸 PATH에 `claude`가 없음 | VM에서 `bash -lc 'command -v claude'` |
| 선택창에 `리뷰: bridge-cse-…` | 세션 이름을 붙이지 않음 (claude.ai 자동 제목은 VM에 오지 않는다) | Desktop 앱에서 세션 이름을 바꾼다. 45초 안에 반영 |
| 끝난 세션이 계속 `리뷰`로 나옴 | 아직 정리하지 않음 | 8장 3번: 리뷰를 마친 세션을 정리한다 |
| 아무 작업도 안 했는데 `리뷰: …`가 하나 있음 | Remote Control 서버가 시작할 때 만든 빈 세션 | 서버를 `--no-create-session-in-dir`로 띄운다 (8장 2번) |
| Hammerspoon 설정 오류 | Lua 오류 | Hammerspoon 앱을 열면 콘솔에 오류가 보인다 |
| 메뉴 막대·HUD 시간이 몇 분 뒤 멈춤 | 모듈 참조가 없어 가비지 컬렉션이 타이머를 멈춤 | `sd.lua`가 `_G.streamingDeck`에 보관 (수정됨) |
| ⌃⌥ 키를 눌렀는데 예전 동작(단축어 알림 표시 등) | 예전 SD 단축어가 키를 먼저 가져감 | 예전 단축어 삭제 (3장) |

## 7. 동작 확인 체크리스트

- [ ] ⌃⌥1 → 데일리 노트·Calendar·Tasks가 열리고 알림, 메뉴 막대 `📌 0/0`, 회색 HUD. MIT를 체크박스로 적으면 `📌 0/N`, 체크하면 완료 수 증가
- [ ] ⌃⌥2 → 선택창에서 MIT 선택 → "Deep 50 시작 ~HH:MM" 알림, 달 아이콘, 로그(`Logs/`)에 `start deep` 줄
- [ ] ⌃⌥3 → 선택창 제목 "Deep 25" → "Deep 25 시작 ~HH:MM" 알림, 25분 후 `end deep25` 줄, 다음 선택창에서 그 작업의 완료가 25분 증가
- [ ] ⌃⌥2 → Esc → "블록 취소됨" 알림, 방해금지 안 켜짐
- [ ] ⌃⌥2 → 목록에 없는 글자 입력 → `＋ 새 작업` 선택 → 로그에 `start deep — 새 작업`, 노트 MIT는 그대로
- [ ] 블록 중 Discord 실행 → 5초 내 종료, "딥 블록 중" 알림, `distraction` 줄
- [ ] 블록 중 메뉴 막대 `🎯 Nm`, 화면 오른쪽 아래 반투명 빨간 HUD에 링 + `MM:SS` + 완료 조건 전체, 끌어서 이동·모서리로 크기 조절
- [ ] 50분 후 "블록 종료" 알림, `end deep` 줄, 달 아이콘 꺼짐, `⏰` → 10분 뒤 `📌`
- [ ] ⌃⌥0 → 방해금지 해제, `shutdown` 줄, 노트 열림, 알림, 메뉴 막대·HUD 사라짐
- [ ] (VM을 쓰면, 8장) ⌃⌥1 알림에 `🤖 …` 줄, ⌃⌥2 선택창 맨 위에 `질문:`·`리뷰:` 세션, 고르면 로그에 `start deep — 리뷰: 세션 이름`

## 8. VM 세션 (adr/007)

구현은 VM의 Claude Code 세션이 맡고, Mac은 VM의 `claude agents --json`만 읽어 Deep 선택창(`질문:`·`리뷰:`), Start Day, Shutdown에 보여준다. VM에 이 저장소의 파일·hook·CLAUDE.md 규칙은 설치하지 않는다. VM을 쓰지 않으면 이 장을 건너뛴다(Start Day에 `! VM 연결 안 됨`만 보인다).

1. **Mac → VM ssh**: 키 인증으로 비밀번호 없이 붙게 하고 `~/.ssh/config`에 별칭을 둔다. `bin/sd`는 `sd-vm`을 쓴다(다른 이름이면 `SD_VM_HOST`, 단 Hammerspoon·Stream Deck은 셸 환경을 물려받지 않으므로 별칭을 맞추는 편이 낫다).
   ```
   Host sd-vm
     HostName <VM 주소>
     User <계정>
   ```
2. **VM에 Remote Control 서버**: 작업 저장소에서 tmux 안에 띄운다. 세션마다 worktree를 받고 권한 확인으로 멈추지 않는다. 시작할 때 빈 세션을 만들지 않게 한다(만들면 늘 `리뷰`로 잡힌다).
   ```bash
   tmux new -d -s cc 'claude remote-control --spawn worktree --permission-mode bypassPermissions --no-create-session-in-dir --name vm'
   ```
3. **쓰기**: Desktop 앱·claude.ai/code·휴대폰에서 이 서버에 새 세션을 띄워 기획을 넘긴다. ⌃⌥2 선택창에서 `리뷰: …`를 고르면 블록이 시작되고 그 세션의 claude.ai 화면이 열린다. 세션을 띄우면 바로 이름을 붙인다(Desktop 앱에서 이름 바꾸기). 그 이름이 VM에도 반영되어 Deep 선택창에 그대로 나온다. 붙이지 않으면 claude.ai의 자동 제목은 VM에 오지 않아 `bridge-cse-…`로 나온다. 리뷰를 마친 세션은 정리해야 할 일 목록에서 빠진다. 정리하지 않은 세션은 다음 날에도 `리뷰`로 나온다.
4. **확인**: 세션 하나를 띄운 뒤 VM에서 `claude agents --json`에 그 세션이 `busy`로 보이고, 끝나면 `idle`이 되고, 정리하면 사라지는지 본다. Mac에서 `bin/sd agents`가 `🤖 …` 한 줄을 낸다. Claude Code를 올린 뒤에는 이 확인을 다시 한다(`claude agents --json` 형식에 기댄다).
