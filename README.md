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

단축어 4개(`SD Start Day` ⌃⌥1, `SD Deep 50` ⌃⌥2, `SD Shutdown` ⌃⌥0, `SD Notify`)를 만든다. 만드는 법, 권한, 문제 해결은 [docs/reference/setup.md](docs/reference/setup.md).

터미널에서 확인: `shortcuts run "SD Deep 50"`
