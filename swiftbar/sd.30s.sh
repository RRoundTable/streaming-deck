#!/bin/zsh
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# 메뉴 막대에는 "🎯 32m", "📌 1/2"처럼 앞부분만 보인다. 전체 문구는 드롭다운과 Hammerspoon HUD.
line=$(${0:A:h:h}/bin/sd status)
[[ -n $line ]] || exit 0
line=${line//|/／}   # '|'는 SwiftBar 파라미터 구분자

short=${line%% · *}
[[ $short == 📌* ]] && color='' || color=' | color=#E5484D'
print -r -- "$short$color"
print -- ---
print -r -- "$line"
