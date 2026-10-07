# polish

선택한 텍스트(없으면 입력창 전체)를 `claude -p --model haiku`로 자연스러운 업무 영어로 고쳐 그 자리에 붙여 넣는다. 영어가 아닌 부분은 번역한다.

| 키 | 하는 일 |
|---|---|
| ⌃⌥E | ⌘C로 선택 복사 → `claude -p` (약 5~8초, 화면에 `✍️ 다듬는 중…`) → ⌘V로 교체 → 원래 클립보드 복원 |

- 선택이 없으면 커서가 있는 입력창 전체(⌘A)를 고친다. 드래그 없이 Claude 앱·Slack 입력창에 쓴 문장을 바로 다듬을 수 있다. 터미널에서는 ⌘A가 화면 전체를 잡으므로 드래그해서 쓴다.
- 기다리는 사이 다른 앱으로 옮기면 붙여 넣지 않고 결과를 클립보드에 남긴다.
- 실패하거나 결과가 비면 아무것도 바꾸지 않고 알림만 띄운다.
- 되묻거나 거절하지 않는다. 짧거나 애매해도 추측해서 번역하고, 질문·지시문("번역하지 마" 포함)도 답하지 않고 그대로 번역한다.
- 프롬프트는 `polish.lua`의 `PROMPT`. `--system-prompt`로 Claude Code 기본 프롬프트를 대신하고 `--tools ""`로 도구를 끈다.

## 설치

`~/.hammerspoon/init.lua`에 한 줄:

```lua
dofile(home .. "/workspace/personal/streaming-deck/tools/polish/polish.lua").start()
```

Stream Deck: Hotkey 액션 하나에 ⌃⌥E.
