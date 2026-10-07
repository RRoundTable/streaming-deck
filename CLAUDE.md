# Project Rules

This project uses the **Techlead** plugin. Follow its guidance on all coding decisions.

- 이 레포는 Stream Deck 프로젝트 여러 개를 담는다. 루트(`bin/`, `hammerspoon/`, `streamdeck-plugin/`, `docs/`)는 업무 모드 시스템 `sd`이고 `docs/GOAL.md`·`ROADMAP.md`는 `sd`에만 적용된다. 독립 도구는 `tools/<이름>/`에 README와 함께 두고 `sd` 코드와 서로 참조하지 않는다.
- 원본 설계문서: `docs/reference/design.md`
- Stream Deck MK.2를 쓴다. 버튼은 Hammerspoon 단축키(⌃⌥1/0)를 보내는 Hotkey 액션, Hammerspoon URL 이벤트로 ⌃⌥2/3과 같은 동작을 부르는 Deep 50·25 플러그인 키(adr/011), 표시 전용 플러그인 키(남은 시간·자리 비움, adr/005·006·009)다. 로직은 `bin/sd`, 앱 계층은 `hammerspoon/sd.lua`, 단축어는 방해금지용 `SD Focus On/Off`뿐이다 (adr/004).
