# Spec

## Capabilities

<!-- Each capability describes a user-observable behavior, not an implementation detail. -->
<!-- Use /propose-spec to add capabilities with Given/When/Then behaviors. -->

(No capabilities defined yet — use `/propose-spec` to define your first feature specification.)

버튼별 동작 초안은 [설계문서 4장 버튼 동작 명세](reference/design.md)에 있다. 구현 전에 Now 항목부터 spec으로 옮긴다.

## Invariants

- 모든 로그 쓰기는 기록 볼트(`SD_VAULT`, 기본 `~/workspace/personal/record-vault`)에만 한다. 업무 볼트에는 쓰지 않는다.
- 집중 로그는 `Logs/YYYY-MM-DD.md`에 `bin/sd`만 덧붙여 쓴다. 데일리 노트는 `![[Logs/YYYY-MM-DD]]`로 보여주기만 하고, `bin/sd`는 데일리 노트를 생성할 때 외에는 쓰지 않는다.
- 집중 로그 줄 형식은 고정이다: `- HH:MM start [deep|deep25|shallow] — 작업명`, `- HH:MM end [deep|deep25|shallow]`(시간을 다 채운 블록. `deep`은 50분, `deep25`는 25분), `- HH:MM shutdown`, `- HH:MM interrupt — 다음: 내용`, `- HH:MM focus N`, `- HH:MM distraction <대상> (closed)`, `- HH:MM override 5m`.
- 완료 조건이 빈칸이면 블록이 시작되지 않는다.
- MIT는 `## MIT`의 leaf 항목(하위 항목이 없는 항목)이고 체크박스로 적는다. `- [x]`는 완료, `- [ ]`와 체크박스 없는 `- `는 미완료다. 하루 진행은 완료한 항목 수 / 전체 항목 수와 다음 미완료 항목이다 (예: `📌 1/6 · InferenceX 페이지 기획`). 시간으로 세지 않는다.
- Deep 선택창에는 VM 세션 후보(질문 → 리뷰) 다음에 미완료 MIT가 나온다. 새 분류는 없다: MIT는 적힌 대로 나오고, VM 후보는 `질문: 세션 이름`·`리뷰: 세션 이름`으로 나와 고르면 그 이름 그대로 `start` 줄에 남는다. VM에 닿지 않으면 VM 후보만 빠진다. MIT 줄 끝의 `[50m]`은 그 작업의 목표 분이고(예전 표기 `[N]`은 N × 50분), 선택창의 작업별 진행(`완료 25/50m`)에만 쓴다. 완료 분은 `end deep` = 50분, `end deep25` = 25분이다.
- Deep 선택창의 작업별 완료 분은 `start … — 작업` 바로 다음 `end` 줄만 그 작업에 더한다. `shutdown`으로 끊긴 블록은 더하지 않는다.
- `state.json`의 `mode`는 `off`(Shutdown), `day`(Start Day 이후), `deep`(블록 중·종료 후) 중 하나다. `bin/sd`만 쓴다.
- 자동 차단(블록 감시·Focus Guard)은 터미널·IDE·Obsidian 등 작업 중인 앱을 종료하지 않는다. 자동 종료 대상은 `BLOCKED_APPS`뿐이다. Shutdown도 앱을 종료하지 않는다.
- HUD는 메뉴 막대를 클릭하면 꺼지고 켜지며, HUD를 클릭하면 접히고 펴진다. 꺼 두어도 딥 블록을 시작하면 다시 켜진다. 메뉴 막대 표시는 HUD와 무관하게 남는다.
- 캘린더 키는 오늘 남은 일정 중 가장 먼저 시작하는 것 하나를 보여준다. 종일 일정, 취소된 일정, 내가 거절한 일정은 건너뛴다. 진행 중이면 `🟢 지금`과 끝나는 시각, 50분 이내에 시작하면 `⏳`과 남은 분(Deep 50이 안 들어간다는 뜻), 그보다 뒤면 `📅`과 시작 시각, 남은 일정이 없으면 `🗓`과 오늘 날짜다. 누르면 Google Calendar 오늘 보기가 열리고, Google과 동기화한 뒤 몇 초 안에 키가 갱신된다. 누르지 않아도 일정은 1분마다 다시 읽고 그때마다 동기화를 요청하므로, Google에서 바꾼 일정은 1~2분 안에 반영된다.
- VM Claude Code 세션의 상태는 VM의 `claude agents --json` status로만 정한다 (adr/007). 세션 쪽 규칙·hook·CLAUDE.md는 두지 않는다. 실행 = `busy`. 질문 = `busy`·`idle`이 아닌 상태(입력·권한 대기). 리뷰 = `idle` (끝났거나 말로 묻고 멈춤 — 둘을 가르지 않는다). 완결 = 내가 정리해서 VM 목록에서 사라진 세션 — 어디에도 나오지 않는다.
- VM 한 줄은 "아이콘 큰 글자 · 윗줄 · 아랫줄"이다. 내 차례(질문 + 리뷰)가 있으면 `🙋 N · 내 차례 · 먼저 볼 세션 이름`, 없고 실행 중이 있으면 `🏃 N · 실행 중 · 내 차례 없음`, 둘 다 없으면 `💤 0 · VM 쉬는 중 · 기획 넘기기`, 읽지 못하면 `! 이유`다. Stream Deck VM 키는 이 줄을 그대로 그린다(보라·초록·주황·회색, 큰 글자는 N). VM은 45초 안에 다시 읽지 않는다. 선택창 VM 후보는 질문 먼저, 각각 먼저 시작한 순이고 설명줄은 `VM · 시작 3h 전`(질문은 `VM · 입력 대기 (상태) · 시작 3h 전`)이다.
- 선택창에서 VM 후보로 블록을 시작하면 그 세션의 claude.ai 화면(`https://claude.ai/code/<세션 id>`)이 열린다. id를 모르면 세션 목록이 열린다.
- 캘린더가 `⏳`(DEEP_MIN 안에 회의)일 때 실행 중인 VM 세션이 0이면 회의마다 한 번 `⏳ N분 뒤 회의 — 실행 중인 VM 세션이 없습니다` 알림을 띄운다. `sd agenda`가 불릴 때(Stream Deck 캘린더 키, 1분마다) 확인한다.
- Start Day 결과에 VM 한 줄이 붙는다. Shutdown 때 실행 중인 VM 세션이 0이면 `⚠️ 밤새 일하는 VM 세션이 없습니다`, VM을 읽지 못하면 `⚠️ VM 확인 실패: 이유`를 함께 알린다. 막지는 않는다.
- 회고·주간 리뷰 답변·집중도 점수는 자동으로 채우지 않는다.
