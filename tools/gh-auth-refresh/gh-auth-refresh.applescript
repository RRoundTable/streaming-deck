-- Terminal 새 창에서 gh auth refresh를 돌린다. 일회용 코드와 브라우저 승인이 TTY를 요구해서 창이 필요하다.
tell application "Terminal"
	activate
	do script "gh auth refresh"
end tell
