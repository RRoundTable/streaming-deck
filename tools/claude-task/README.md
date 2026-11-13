# claude-task

Claude 데스크톱 앱의 예약 작업을 Stream Deck 버튼으로 지금 실행한다. 앱의 "지금 실행"을 부르는 게 아니라, 같은 프롬프트를 `claude -p`로 돌린다.

| 키 | 하는 일 |
|---|---|
| Open 액션 → `Claude Daily Scrum.app` | `daily-scrum` 프롬프트를 백그라운드로 실행 → 시작·완료 알림 → 결과 파일을 텍스트 편집기로 연다 |

## 동작

1. `~/.claude/scheduled-tasks/<작업>/SKILL.md`에서 frontmatter를 떼고 본문을 프롬프트로 쓴다. 앱에서 프롬프트를 고치면 다음 실행부터 바로 반영된다. 다시 빌드할 필요 없다.
2. `$HOME`에서 `claude -p --permission-mode bypassPermissions`로 실행한다. 예약 작업처럼 중간에 묻지 않고 끝까지 간다.
3. 출력은 `~/Library/Logs/claude-task/<작업>-<시각>.md`에 남는다. 끝나면 알림을 띄우고 이 파일을 연다.

- 실행 중에 다시 누르면 "이미 실행 중" 알림만 뜬다.
- 데스크톱 앱의 작업 기록에는 남지 않는다. 예약 실행은 앱이 그대로 한다.
- 권한 확인을 끄므로 프롬프트가 시키는 일(`gh issue edit` 등)을 그대로 한다. 버튼에 올릴 작업의 프롬프트는 미리 읽어 둔다.

## 설치

작업마다 앱 하나를 만든다.

```bash
tools/claude-task/build.sh daily-scrum "Claude Daily Scrum"
```

`~/Applications/Claude Daily Scrum.app`이 만들어진다. Stream Deck: **System → Open** 액션을 키에 올리고 App/File에 이 앱을 지정한다.

다른 작업도 같은 방법으로 만든다. 예: `build.sh pr "Claude PR"`.
