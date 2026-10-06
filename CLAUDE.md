# Project Rules

This project uses the **Techlead** plugin. Follow its guidance on all coding decisions.

- 원본 설계문서: `docs/reference/design.md`
- Stream Deck MK.2를 쓴다. 버튼은 Hammerspoon 단축키(⌃⌥1/2/3/0)를 보내는 Hotkey 액션과 표시 전용 플러그인 키(남은 시간·캘린더·VM 세션, adr/005~007)다. 로직은 `bin/sd`, 앱 계층은 `hammerspoon/sd.lua`, 단축어는 방해금지용 `SD Focus On/Off`뿐이다 (adr/004).
- VM Claude Code 세션 상태는 `bin/sd agents`가 ssh(`Host sd-vm`)로 VM의 `claude agents --json`만 읽는다. VM에는 이 저장소의 어떤 것도 설치하지 않는다 (adr/007).
