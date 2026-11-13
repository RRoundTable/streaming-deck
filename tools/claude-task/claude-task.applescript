-- Stream Deck이 여는 앱 본체. 번들된 task.txt의 작업을 run.sh로 백그라운드 실행하고 바로 끝난다.
on run
	set res to POSIX path of (path to resource "run.sh")
	set task to do shell script "cat " & quoted form of POSIX path of (path to resource "task.txt")
	do shell script quoted form of res & " " & quoted form of task & " >/dev/null 2>&1 &"
end run
