# Roadmap

설계문서 9·10장 기준. 버튼 4개로 시작해 기록을 보고 늘리거나 줄인다.

## Now — 입사 전 (~2026-09-27)

- [x] 기록 볼트 생성 (`~/workspace/personal/record-vault`): `Daily/`, `Weekly/`, `Goals/`, `Inbox.md`, `Templates/`, 데일리 노트 템플릿, 코어 Daily Notes·Templates 설정
- [x] Obsidian에 볼트 등록
- [x] `bin/sd`: 데일리 노트 생성, `## 집중 로그`에 줄 추가, 완료 조건 입력창, state.json, 종료 알림 (Advanced URI 대신 파일 직접 수정)
- [x] 딥 블록 중 Discord·KakaoTalk 실행 차단 + `distraction` 로그 (Focus Guard 중 앱 차단만 앞당김, 사용자 요청 2026-09-26)
- [x] 단축어 `SD Start Day`, `SD Deep 50`, `SD Shutdown` + 키보드 단축키(⌃⌥1, ⌃⌥2, ⌃⌥0)
- [x] 완료 알림: 각 단축어 마지막 `알림 표시`, 백그라운드 알림은 `SD Notify` 경유
- [x] 메뉴 막대에 블록 남은 시간·작업명 표시 (SwiftBar, ADR-001, 사용자 요청 2026-09-26)
- [ ] `SD Notify` "항상 허용" 후 블록 종료 알림 실제 확인 ([setup.md 7장](reference/setup.md) 체크리스트)

완료 기준: ⌃⌥1로 오늘 데일리 노트가 열리고, ⌃⌥2 → 50분 후 알림 → 집중 로그에 `start` 줄이 남는다.

## Next — 1~2주차 (2026-09-28~)

- [ ] 1주차: Start Day / Deep 50 / Shutdown을 실제 업무에 사용, 안 누르는 동작 제거
- [ ] `SD Shallow 25`, `SD Interrupt`, `SD Focus 1`~`SD Focus 5`, 인박스 메모
- [ ] 블록 종료 → 집중도 입력 강제(평가 없이 휴식으로 못 넘어가게)

## Later — 3~4주차

- [ ] ActivityWatch 설치, 주간 리뷰 노트 집계 숫자 자동 채우기
- [ ] Slack 상태 연동 (회사 워크스페이스 개인 토큰 발급 가능 여부 먼저 확인)
- [ ] iTerm2 Triggers로 에이전트 완료 알림
- [ ] Focus Guard 데몬: 브라우저 URL·회색지대 판정 (알림 전용 → 오탐 확인 후 차단 목록 탭 닫기)
- [ ] Stream Deck 도착 시 Hotkey 액션으로 연결, 페이지·집중도 폴더·타이머 표시 구성

## 미결 사항

- [x] 기록 볼트 경로 → `~/workspace/personal/record-vault` (vault 이름 `record-vault`)
- [x] Tasks → Google Tasks (`https://tasks.google.com`)
- [ ] Stream Deck 모델 (버튼 수·다이얼)
- [ ] 회사 Slack 개인 API 토큰 가능 여부
- [ ] 팀 리듬 파악 후 하루 시간표 조정
- [ ] 분기 목표 노트 `Goals/2026-Q4.md` 작성
