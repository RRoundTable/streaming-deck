---
name: setup-streaming-deck
description: 새 MacBook에 streaming-deck 업무 모드 시스템(bin/sd, 기록 볼트, SD 단축어, SwiftBar 메뉴 막대)을 설치하고 동작을 확인한다. "다른 맥에 설치", "새 맥북 세팅", "streaming-deck 이식", "sd 설치" 요청에 사용.
---

# streaming-deck 설치 (새 Mac)

이 저장소를 clone한 Mac에서 실행한다. 자동화 가능한 부분은 `bin/setup`이 하고, macOS가 막아 둔 부분(단축어 생성, 시스템 설정, 권한 허용)은 사용자에게 정확한 값과 함께 안내한다. 상세 설명과 문제 해결은 `docs/reference/setup.md`에 있다. 단계마다 그 문서의 해당 장을 읽고 안내한다.

## 원칙

- 설치·다운로드(brew)는 실행 전에 사용자에게 확인받는다.
- 시스템 설정은 직접 바꾸지 않는다. 경로를 알려주고 사용자가 바꾼다.
- 단축어는 CLI로 만들 수 없다. 사용자가 만들고, `shortcuts list`로 확인한다.
- 기존 볼트·파일은 덮어쓰지 않는다. `bin/setup`은 없는 파일만 복사한다.
- 앱 숨기기·종료 테스트는 사용자의 실제 앱(Slack, 카카오톡 등)에 영향을 주므로, 실행 전에 알린다.

## 1. 사전 확인

```bash
uname -s                                   # Darwin
sw_vers -productVersion                    # 15.x 기준으로 검증됨
git -C <repo> rev-parse --show-toplevel    # 저장소 경로 = REPO
ls /Applications | grep -E "Obsidian|SwiftBar"
which brew
```

사용자에게 한 번에 묻는다:
1. 기록 볼트 위치. 기본값은 `~/workspace/personal/record-vault`다. 다르면 이후 모든 명령에 `SD_VAULT=<경로>`를 붙인다.
2. 없는 앱(Obsidian, SwiftBar)을 brew로 설치해도 되는지.

## 2. 앱 설치 (승인 후)

```bash
brew install --cask obsidian    # 없을 때만
brew install --cask swiftbar    # 없을 때만
```

## 3. bin/setup 실행

```bash
<REPO>/bin/setup                       # 기본 볼트
SD_VAULT=<경로> <REPO>/bin/setup       # 다른 볼트
```

출력의 ✓/✗를 사용자에게 요약한다. 마지막에 출력되는 "셸 스크립트 실행에 넣을 명령" 3줄은 5단계에서 그대로 쓴다.

그다음 SwiftBar를 실행한다: `open -a SwiftBar`. 로그인 시 자동 실행은 SwiftBar → Preferences → Launch at login에서 사용자가 켠다.

## 4. Obsidian 볼트 등록 (사용자)

Obsidian → 볼트 전환 → "Open folder as vault" → 기록 볼트 폴더. 볼트 이름은 폴더 이름이 되고, `sd`는 폴더 이름으로 `obsidian://open?vault=`를 호출한다.

## 5. 단축어 4개 (사용자)

`docs/reference/setup.md` 2장(사전 준비)과 3장(단축어 만들기)을 읽고 안내한다. 경로는 3단계 출력값으로 바꿔서 제시한다.

| 단축어 | 키 | 액션 |
|---|---|---|
| SD Start Day | ⌃⌥1 | 셸 스크립트 실행(start-day) → 알림 표시: 셸 스크립트 결과 |
| SD Deep 50 | ⌃⌥2 | 셸 스크립트 실행(deep) → 날짜 조정 +50분 → 집중 모드 설정: 방해금지 켜기, 끝 = 조정된 날짜 → 알림 표시: 셸 스크립트 결과 |
| SD Shutdown | ⌃⌥0 | 셸 스크립트 실행(shutdown) → 집중 모드 설정: 방해금지 끄기 → 알림 표시: 셸 스크립트 결과 |
| SD Notify | 없음 | ⓘ → 빠른 동작으로 사용 체크 → 알림 표시: 단축어 입력 |

먼저 단축어 앱 → 설정 → 고급 → "스크립트 실행 허용"을 켜게 한다.

사용자가 만들었다고 하면 `bin/setup`을 다시 실행해 "✓ 단축어 4개"를 확인한다.

## 6. 시스템 설정과 권한 (사용자)

- 시스템 설정 → 제어 센터 → 집중 모드 → 메뉴 막대에서 보기: 활성화될 때
- `SD Notify` 첫 호출 시 "계속하겠습니까" 알림 → 옵션 → 항상 허용:
  ```bash
  echo "알림 테스트" > /tmp/n.txt && shortcuts run "SD Notify" -i /tmp/n.txt
  ```
  명령이 끝나지 않으면 권한 확인을 기다리는 중이다. 사용자에게 알림 센터를 보게 한다.
- 선택: 전용 집중 모드 "딥워크"와 다크 모드 필터 (setup.md 4장)

## 7. 동작 확인

`docs/reference/setup.md` 7장 체크리스트를 사용자와 함께 확인한다. Claude가 직접 확인할 수 있는 것:

```bash
cat ~/.focus/state.json                                          # 블록 상태
cat <볼트>/Logs/$(date +%F).md                                   # 로그 줄 (노트에는 임베드)
/bin/ps -axo command | grep "[_]guard"                          # 블록 감시 프로세스
<REPO>/swiftbar/sd.30s.sh                                       # 메뉴 막대 출력
```

알림 표시, 달 아이콘, 메뉴 막대처럼 화면에 보이는 것은 Claude가 볼 수 없다(화면 기록·알림 DB 권한 없음). 사용자에게 물어서 확인한다.

## 알려진 문제

setup.md 6장 표를 먼저 본다. 자주 나오는 것:
- 변수 목록에 "단축어 입력"이 없음 → SD Notify의 "빠른 동작으로 사용"이 꺼져 있음
- 알림이 안 뜨고 알림 센터에도 없음 → "계속하겠습니까" 권한 대기
- 달 아이콘 안 보임 → 제어 센터 메뉴 막대 설정
- 테스트용 감시 프로세스를 끌 때 `pkill -f "sd _guard"`처럼 넓게 쓰지 말 것. 실제 블록의 감시까지 꺼진다. started 값까지 넣어 좁힌다.
