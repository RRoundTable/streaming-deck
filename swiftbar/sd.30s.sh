#!/bin/zsh
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# 메뉴 막대 표시. ~/.focus/state.json, 오늘 노트(MIT), 오늘 로그를 읽기만 한다.
#   딥 블록 중          🎯 32m · 완료 조건
#   블록 종료 후 10분    ⏰ 블록 종료 — 집중도 기록
#   Start Day 이후      📌 1/2 · MIT   (완료 블록 수 / MIT의 [N], 없으면 3)
#   Shutdown·다른 날    표시 없음
export LC_ALL=en_US.UTF-8   # 한글을 글자 단위로 자르기 위해
STATE=$HOME/.focus/state.json
VAULT=${SD_VAULT:-$HOME/workspace/personal/record-vault}
NOTE=$VAULT/Daily/$(date +%F).md
LOG=$VAULT/Logs/$(date +%F).md
BREAK_MIN=10
DEFAULT_BLOCKS=3
RED='| color=#E5484D'

[[ -f $STATE ]] || exit 0
field() { sed -n "s/.*\"$1\": \"\([^\"]*\)\".*/\1/p" $STATE }
clean() { local s=${1//|/／}; print -r -- $s }   # '|'는 SwiftBar 파라미터 구분자

show_day() {
  local mit=$(awk '/^## /{ in_mit = ($0 == "## MIT"); next }
                   in_mit && sub(/^- /, "") && $0 != "" { print; exit }' $NOTE 2>/dev/null)
  local target=$DEFAULT_BLOCKS done_=0
  [[ $mit =~ ' *\[([0-9]+)\] *$' ]] && { target=$match[1]; mit=${mit[1,MBEGIN-1]}; }
  [[ -f $LOG ]] && done_=$(grep -c '^- [0-9:]* end deep$' $LOG)
  mit=$(clean $mit)
  print -r -- "📌 $done_/$target · ${${mit:-MIT를 적으세요}[1,20]}"
  print -- ---
  print -r -- "${mit:-MIT 없음}"
  print "완료 딥 블록 $done_ / 목표 $target"
}

case $(field mode) in
  day)
    [[ $(field date) == $(date +%F) ]] && show_day ;;
  deep)
    started=$(field started) ends=$(field ends)
    [[ ${started[1,10]} == $(date +%F) ]] || exit 0
    left=$(( ($(date -j -f %FT%T $ends +%s) - $(date +%s) + 59) / 60 ))
    task=$(clean "$(field task)")
    if (( left > 0 )); then
      print -r -- "🎯 ${left}m · ${task[1,20]} $RED"
      print -- ---
      print -r -- "$task"
      print "종료 ~${ends[12,16]}"
    elif (( left > -BREAK_MIN )); then
      print "⏰ 블록 종료 — 집중도 기록 $RED"
    else
      show_day
    fi ;;
esac
exit 0
