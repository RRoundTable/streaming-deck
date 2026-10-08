-- Stream Deck이 여는 앱 본체. 실제 일은 같이 번들된 refresh.sh가 한다.
on run
	do shell script quoted form of POSIX path of (path to resource "refresh.sh")
end run
