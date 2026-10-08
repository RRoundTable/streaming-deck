# gh-auth-refresh

버튼 하나로 `gh auth refresh`를 실행한다. Terminal 새 창이 열리고 일회용 코드가 뜨면 Enter → 브라우저에서 승인하면 끝난다. `gh` 토큰이 만료됐거나 scope를 갱신할 때 쓴다.

| 키 | 하는 일 |
|---|---|
| Open 액션 → `GH Auth Refresh.app` | Terminal 창을 열어 `gh auth refresh` 실행 |

`gh auth refresh`는 코드 입력과 Enter를 받는 TTY가 필요해서 창 없이 백그라운드로 돌릴 수 없다.

## 설치

```bash
tools/gh-auth-refresh/build.sh
```

`~/Applications/GH Auth Refresh.app`이 만들어진다. 처음 실행하면 macOS가 "Terminal을 제어하도록 허용" 확인을 한 번 묻는다. 허용한다.

Stream Deck: **System → Open** 액션을 키에 올리고 App/File에 `~/Applications/GH Auth Refresh.app`을 지정한다.

scope를 더하려면 `gh-auth-refresh.applescript`의 명령을 `gh auth refresh -s <scope>`로 바꾸고 `build.sh`를 다시 돌린다.
