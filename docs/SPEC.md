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
- Deep 선택창에는 미완료 MIT만 나온다. 줄 끝의 `[50m]`은 그 작업의 목표 분이고(예전 표기 `[N]`은 N × 50분), 선택창의 작업별 진행(`완료 25/50m`)에만 쓴다. 완료 분은 `end deep` = 50분, `end deep25` = 25분이다.
- Deep 선택창의 작업별 완료 분은 `start … — 작업` 바로 다음 `end` 줄만 그 작업에 더한다. `shutdown`으로 끊긴 블록은 더하지 않는다.
- `state.json`의 `mode`는 `off`(Shutdown), `day`(Start Day 이후), `deep`(블록 중·종료 후) 중 하나다. `bin/sd`만 쓴다.
- 자동 차단(블록 감시·Focus Guard)은 터미널·IDE·Obsidian 등 작업 중인 앱을 종료하지 않는다. 자동 종료 대상은 `BLOCKED_APPS`뿐이다. Shutdown도 앱을 종료하지 않는다.
- HUD는 메뉴 막대를 클릭하면 꺼지고 켜지며, HUD를 클릭하면 접히고 펴진다. 꺼 두어도 딥 블록을 시작하면 다시 켜진다. 메뉴 막대 표시는 HUD와 무관하게 남는다.
- 자리 비움 키는 내가 일할 수 없는 시간(공백)을 미리 알려, 그 전에 Remote Control로 넘길 작업을 정하게 한다. 공백은 오늘 남은 일정(종일·취소·거절한 일정 제외), 근무일의 점심 12:00–13:00·저녁 18:00–19:00, 퇴근(19:00부터 다음 근무일 09:00까지)이다. 근무일은 주말도 공휴일도 아닌 날이다. 이어지거나 겹치는 공백은 하나로 보고, 이름은 그중 가장 긴 것을 쓴다.
- 자리 비움 키 윗칸은 가장 가까운 공백, 아랫칸은 다음 긴 공백(3시간 이상)이다. 칸마다 이름, 시작까지 남은 시간, `↦` 비우는 길이를 보인다(하루 이상은 일 단위, 예: 금요일 퇴근 `↦2d`). 진행 중인 공백은 `지금`과 끝날 때까지 남은 길이다. 둘이 같은 공백이면 한 칸으로 크게 보인다. 이름은 휴일 전날에도 `퇴근`이다.
- 자리 비움 키 색은 오래 비울수록 일찍 바뀐다. 3시간 미만 공백은 30분 전 주황·10분 전 빨강, 3시간 이상은 90분 전·20분 전, 2일 이상은 3시간 전·30분 전이다. 두 칸 중 급한 쪽을 따르고, 그 전에는 어두운 회색이다.
- 자리 비움 키를 누르면 Google Calendar 오늘 보기가 열리고, Google과 동기화한 뒤 몇 초 안에 키가 갱신된다. 누르지 않아도 일정은 1분마다 다시 읽고 그때마다 동기화를 요청하므로, Google에서 바꾼 일정은 1~2분 안에 반영된다. 공휴일 캘린더(이름에 "휴일"이나 "Holiday"가 든 캘린더)가 없으면 키에 `공휴일 캘린더 없음`이 보인다.
- 회고·주간 리뷰 답변·집중도 점수는 자동으로 채우지 않는다.
