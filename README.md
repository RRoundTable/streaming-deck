# streaming-deck

키보드 단축키(나중에 Stream Deck)로 업무 모드를 바꾸고 Obsidian 기록 볼트에 로그를 남긴다. 목표와 설계는 [docs/GOAL.md](docs/GOAL.md), [docs/reference/design.md](docs/reference/design.md).

## 동작

```
bin/sd start-day        # 데일리 노트 생성 → Google Calendar·Tasks·노트 열기
bin/sd deep [완료 조건]   # 입력창(기본값: 직전 '다음:' 또는 MIT) → 로그 → state.json → Slack·Mail 숨김 → 50분 동안 Discord·KakaoTalk 실행 시 즉시 종료 + distraction 로그 → 종료 알림
bin/sd shutdown         # state.json off → 데일리 노트 열기 → iTerm2 종료
```

기록 볼트: `~/workspace/personal/record-vault` (`SD_VAULT`로 변경 가능)

## 단축어 설정

단축어 앱 → 설정 → 고급 → **스크립트 실행 허용**을 켠다. 각 단축어의 ⓘ → **키보드 단축키 추가**.

| 단축어 | 액션 | 키 |
|---|---|---|
| `SD Start Day` | 셸 스크립트 실행: `~/workspace/personal/streaming-deck/bin/sd start-day` | ⌃⌥1 |
| `SD Deep 50` | 셸 스크립트 실행: `~/workspace/personal/streaming-deck/bin/sd deep` → 날짜 조정(현재 날짜 + 50분) → 집중 모드 설정: 방해금지 켜기, 끝: 시간(조정된 날짜) | ⌃⌥2 |
| `SD Shutdown` | 셸 스크립트 실행: `~/workspace/personal/streaming-deck/bin/sd shutdown` → 집중 모드 설정: 방해금지 끄기 | ⌃⌥0 |

셸 스크립트 실행의 셸은 `zsh`, 입력 전달은 사용 안 함. 처음 실행하면 System Events 제어(앱 숨기기) 권한을 묻는다.

터미널에서 확인: `shortcuts run "SD Deep 50"`
