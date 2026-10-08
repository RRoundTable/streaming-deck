-- 사용: osascript drive.applescript <step.js 경로> <gcloud PID> <인증 URL>
-- Aside에 새 탭으로 인증 URL을 열고 step.js를 1초마다 돌려 로그인을 진행한다. 마지막 상태를 출력한다.
on isAlive(pid)
	try
		do shell script "kill -0 " & pid
		return true
	on error
		return false
	end try
end isAlive

on run argv
	set jsSource to read POSIX file (item 1 of argv)
	set pid to item 2 of argv
	set status to "timeout"
	set warned to false

	tell application "Aside"
		if (count of windows) is 0 then make new window
		set t to make new tab at end of tabs of front window with properties {URL:(item 3 of argv)}
		repeat 300 times
			delay 1
			if not my isAlive(pid) then
				set status to "gcloud-exited"
				exit repeat
			end if
			set s to ""
			try
				tell t to set s to execute javascript jsSource
			end try
			if s starts with "failure" then
				set status to s
				exit repeat
			end if
			if (s starts with "external" or s is "login_required") and not warned then
				set warned to true
				display notification "Aside에서 구글 로그인(비밀번호/2단계)을 끝내면 이어서 진행합니다" with title "gcloud auth"
			end if
		end repeat
		try
			close t
		end try
	end tell
	return status
end run
