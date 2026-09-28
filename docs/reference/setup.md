# 설정 가이드 (Stream Deck 없이 키보드 단축키로)

2026-09-27 기준. macOS 15, Hammerspoon 1.1.

## 1. 구조

앱은 Hammerspoon 하나다(adr/004). 로직은 전부 `bin/sd`에 있고, Hammerspoon은 연결만 한다.

| 계층 | 담당 | 저장 위치 |
|---|---|---|
| Hammerspoon (`hammerspoon/sd.lua`) | ⌃⌥1/2/3/0 단축키, 메뉴 막대, 화면 구석 HUD, 알림 | 저장소 (init.lua가 불러옴) |
| `bin/sd` | 데일리 노트 생성, 집중 로그, 선택창 후보(`sd tasks`), `~/.focus/state.json`, 앱 숨기기·종료, 블록 중 앱 차단, 방해금지 on/off 호출, 상태 문구 | 저장소 |
| 단축어 `SD Focus On`/`SD Focus Off` | 방해금지 켜기·끄기 (macOS에 CLI가 없어서) | macOS |

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

`bin/sd status`가 상태 한 줄을 만든다. Hammerspoon이 메뉴 막대에는 ` · ` 앞부분만, 화면 오른쪽 아래 HUD에는 전체 문구를 항상 위에 보여준다. 20초마다, 그리고 `~/.focus`가 바뀔 때마다 갱신한다.

| 상태 | 메뉴 막대 | HUD (전체 문구) |
|---|---|---|
| Start Day 전, Shutdown 후, 날짜가 바뀜 | 없음 | 없음 |
| Start Day 이후, 블록 사이 | `📌 75/150m` | `📌 75/150m · MIT` (오늘 끝낸 딥 블록 분 / 첫 MIT의 목표 분, 없으면 150), 회색 |
| 딥 블록 중 | `🎯 32m` (빨강) | `🎯 32m · 완료 조건`, 빨강 |
| 블록 종료 후 10분 | `⏰ 블록 종료` | `⏰ 블록 종료 · 집중도를 기록하고 쉬세요` → 이후 `📌` |

- MIT 줄 끝에 목표 분을 적는다: `- 메모리 모듈 설계 [100m]`. 예전 표기 `[2]`는 100분으로 읽는다. Deep 선택창에는 MIT의 leaf 항목(하위 항목이 없는 것)만 나온다. 하위 항목이 있는 상위 항목은 목록에서 빠진다. 목표는 빠지고 `완료 75/100m`처럼 작업별 진행이 붙는다.
- 선택창에서 목록에 없는 작업을 입력하면 `＋ 새 작업`으로 시작된다. 노트 MIT에는 쓰지 않고 로그의 `start` 줄로만 남는다. 선택창에 다시 나오게 하려면 노트 MIT에 직접 적는다.
- 위치·색·갱신 주기·단축키는 `hammerspoon/sd.lua` 상단 상수. 바꾼 뒤 Hammerspoon 앱을 열어 콘솔에서 `hs.reload()`.
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

남은 시간 키: 블록 중 빨강 `DEEP 32m`, 종료 후 빨강 `휴식`, 블록 사이 회색 `MIT 75 /150m`, Start Day 전·Shutdown 후 어두운 `sd`. 플러그인이 `bin/sd status --short`를 5초마다, `~/.focus`가 바뀔 때 바로 읽는다. 키를 누르면 즉시 새로고침. 메뉴 막대와 같은 `sd status`를 읽으므로 블록 시간과 어긋나지 않는다.

플러그인 코드를 고친 뒤: `cd streamdeck-plugin && npm run build && npx streamdeck restart com.rroundtable.sd`. 처음 링크한 뒤에는 Stream Deck 앱을 한 번 재시작해야 목록에 나온다. 로그: `streamdeck-plugin/com.rroundtable.sd.sdPlugin/logs/`.

## 5. 첫 실행 권한

| 요청 | 언제 | 선택 |
|---|---|---|
| Hammerspoon 알림 | 첫 알림 | 허용 |
| Hammerspoon이 System Events 제어 | 앱 숨기기 처음 사용 | 허용 |
| "계속하겠습니까" (알림 형태) | `SD Focus On/Off` 첫 호출 | 옵션 → 항상 허용 |

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
| Hammerspoon 설정 오류 | Lua 오류 | Hammerspoon 앱을 열면 콘솔에 오류가 보인다 |
| 메뉴 막대·HUD 시간이 몇 분 뒤 멈춤 | 모듈 참조가 없어 가비지 컬렉션이 타이머를 멈춤 | `sd.lua`가 `_G.streamingDeck`에 보관 (수정됨) |
| ⌃⌥ 키를 눌렀는데 예전 동작(단축어 알림 표시 등) | 예전 SD 단축어가 키를 먼저 가져감 | 예전 단축어 삭제 (3장) |

## 7. 동작 확인 체크리스트

- [ ] ⌃⌥1 → 데일리 노트·Calendar·Tasks가 열리고 알림, 메뉴 막대 `📌 0/150m`, 회색 HUD
- [ ] ⌃⌥2 → 선택창에서 MIT 선택 → "Deep 50 시작 ~HH:MM" 알림, 달 아이콘, 로그(`Logs/`)에 `start deep` 줄
- [ ] ⌃⌥3 → 선택창 제목 "Deep 25" → "Deep 25 시작 ~HH:MM" 알림, 25분 후 `end deep25` 줄, 📌 완료가 25분 증가
- [ ] ⌃⌥2 → Esc → "블록 취소됨" 알림, 방해금지 안 켜짐
- [ ] ⌃⌥2 → 목록에 없는 글자 입력 → `＋ 새 작업` 선택 → 로그에 `start deep — 새 작업`, 노트 MIT는 그대로
- [ ] 블록 중 Discord 실행 → 5초 내 종료, "딥 블록 중" 알림, `distraction` 줄
- [ ] 블록 중 메뉴 막대 `🎯 Nm`, 화면 오른쪽 아래 빨간 HUD에 완료 조건 전체
- [ ] 50분 후 "블록 종료" 알림, `end deep` 줄, 달 아이콘 꺼짐, `⏰` → 10분 뒤 `📌`
- [ ] ⌃⌥0 → 방해금지 해제, `shutdown` 줄, 노트 열림, iTerm2 종료, 알림, 메뉴 막대·HUD 사라짐
