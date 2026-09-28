# Roadmap

설계문서 9·10장 기준. 버튼 4개로 시작해 기록을 보고 늘리거나 줄인다.

## Now — 입사 전 (~2026-09-27)

완료 기준: ⌃⌥1로 오늘 데일리 노트가 열리고, ⌃⌥2 → 50분 후 알림 → 집중 로그에 `start`·`end` 줄이 남는다.

기록
- [x] 기록 볼트 `~/workspace/personal/record-vault`: `Daily/`, `Logs/`, `Weekly/`, `Goals/`, `Inbox.md`, 데일리 노트 템플릿
- [x] 집중 로그는 `Logs/YYYY-MM-DD.md`, 데일리 노트에 링크+임베드 (ADR-002, 편집 충돌 제거)
- [x] 로그 이벤트: `start`, `end`, `shutdown`, `distraction`

동작 (`bin/sd`)
- [x] start-day / deep / shutdown / status
- [x] 딥 블록 중 Discord·KakaoTalk 실행 즉시 종료 (Focus Guard 중 앱 차단만 앞당김)
- [x] 방해금지를 블록 시작·종료·Shutdown에 맞춰 on/off (`SD Focus On/Off`)
- [x] MIT `[N]`으로 필요한 딥 블록 수 지정

앱 계층 (Hammerspoon 하나, ADR-004)
- [x] ⌃⌥1/2/0 단축키, 결과 알림, 백그라운드 알림(`~/.focus/notify`)
- [x] 메뉴 막대 `🎯 32m`/`📌 1/2` + 화면 오른쪽 아래 HUD에 전체 문구 (ADR-003)
- [x] 예전 SD 단축어 4개 삭제, `SD Focus On/Off` 생성 (2026-09-27)

이식
- [x] `bin/setup` + `vault-template/` + `setup-streaming-deck` skill

확인 남음
- [x] 한 블록 전체를 Hammerspoon 경로로 (확인 2026-09-27): HUD 시간 감소, 50분 후 알림·`end deep`·방해금지 해제 ([setup.md 7장](reference/setup.md))

## Next — 1~2주차 (2026-09-28~)

- [ ] 1주차: Start Day / Deep 50 / Shutdown을 실제 업무에 사용, 안 누르는 동작 제거
- [ ] `SD Shallow 25`, `SD Interrupt`, `SD Focus 1`~`SD Focus 5`, 인박스 메모
- [ ] 블록 종료 → 집중도 입력 강제(평가 없이 휴식으로 못 넘어가게)

## Later — 3~4주차

- [ ] ActivityWatch 설치, 주간 리뷰 노트 집계 숫자 자동 채우기
- [ ] Slack 상태 연동 (회사 워크스페이스 개인 토큰 발급 가능 여부 먼저 확인)
- [ ] iTerm2 Triggers로 에이전트 완료 알림
- [ ] Focus Guard 데몬: 브라우저 URL·회색지대 판정 (알림 전용 → 오탐 확인 후 차단 목록 탭 닫기)
- [ ] Stream Deck 도착 시 Hotkey 액션으로 연결, 페이지·집중도 폴더 구성
- [x] Stream Deck 남은 시간 키: 자체 표시 전용 플러그인 `streamdeck-plugin/` (ADR-005, 2026-09-28)

## 미결 사항

- [x] 기록 볼트 경로 → `~/workspace/personal/record-vault` (vault 이름 `record-vault`)
- [x] Tasks → Google Tasks (`https://tasks.google.com`)
- [x] Stream Deck 모델 → MK.2 (15키, 3×5, 다이얼 없음). 설계문서 가정과 같음 (2026-09-28)
- [ ] 회사 Slack 개인 API 토큰 가능 여부
- [ ] 팀 리듬 파악 후 하루 시간표 조정
- [ ] 분기 목표 노트 `Goals/2026-Q4.md` 작성
