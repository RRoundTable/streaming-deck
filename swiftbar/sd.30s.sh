#!/bin/zsh
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# 딥 블록 중 메뉴 막대에 남은 시간과 작업명을 표시한다. ~/.focus/state.json을 읽기만 한다.
export LC_ALL=en_US.UTF-8   # 한글 작업명을 글자 단위로 자르기 위해
STATE=$HOME/.focus/state.json
[[ -f $STATE ]] || exit 0

field() { sed -n "s/.*\"$1\": \"\([^\"]*\)\".*/\1/p" $STATE }

[[ $(field mode) == deep ]] || exit 0
task=$(field task)
task=${task//|/／}   # '|'는 SwiftBar 파라미터 구분자
ends=$(field ends)
left=$(( ($(date -j -f %FT%T $ends +%s) - $(date +%s) + 59) / 60 ))

if (( left > 0 )); then
  print -r -- "🎯 ${left}m · ${task[1,20]} | color=#E5484D"
else
  print "⏰ 블록 종료 — 집중도 기록 | color=#E5484D"
fi
print -- ---
print -r -- "$task"
print "종료 ~${ends[12,16]}"
