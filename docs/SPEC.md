# Spec

## Capabilities

<!-- Each capability describes a user-observable behavior, not an implementation detail. -->
<!-- Use /propose-spec to add capabilities with Given/When/Then behaviors. -->

(No capabilities defined yet — use `/propose-spec` to define your first feature specification.)

버튼별 동작 초안은 [설계문서 4장 버튼 동작 명세](reference/design.md)에 있다. 구현 전에 Now 항목부터 spec으로 옮긴다.

## Invariants

- 모든 로그 쓰기는 기록 볼트(`SD_VAULT`, 기본 `~/workspace/personal/record-vault`)에만 한다. 업무 볼트에는 쓰지 않는다.
- 집중 로그는 `Logs/YYYY-MM-DD.md`에 `bin/sd`만 덧붙여 쓴다. 데일리 노트는 `![[Logs/YYYY-MM-DD]]`로 보여주기만 하고, `bin/sd`는 데일리 노트를 생성할 때 외에는 쓰지 않는다.
- 집중 로그 줄 형식은 고정이다: `- HH:MM start [deep|shallow] — 작업명`, `- HH:MM end [deep|shallow]`(시간을 다 채운 블록), `- HH:MM shutdown`, `- HH:MM interrupt — 다음: 내용`, `- HH:MM focus N`, `- HH:MM distraction <대상> (closed)`, `- HH:MM override 5m`.
- 완료 조건이 빈칸이면 블록이 시작되지 않는다.
- MIT는 `## MIT`의 첫 항목이다. 줄 끝의 `[N]`은 필요한 딥 블록 수이고, 없으면 3으로 본다. 완료 블록 수는 오늘 노트의 `end deep` 줄 수다.
- `state.json`의 `mode`는 `off`(Shutdown), `day`(Start Day 이후), `deep`(블록 중·종료 후) 중 하나다. `bin/sd`만 쓴다.
- 자동 차단(블록 감시·Focus Guard)은 터미널·IDE·Obsidian 등 작업 중인 앱을 종료하지 않는다. 자동 종료 대상은 `BLOCKED_APPS`뿐이다. (Shutdown의 iTerm2 종료는 사용자가 누른 정상 종료다.)
- 회고·주간 리뷰 답변·집중도 점수는 자동으로 채우지 않는다.
