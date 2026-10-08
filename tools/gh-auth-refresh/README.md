# gh-auth-refresh

버튼 하나로 `gh auth refresh -s <scopes>`를 끝까지 실행한다. 일회용 코드 입력과 Authorize 클릭을 Aside 브라우저에서 대신 한다. 끝나면 알림이 뜬다.

| 키 | 하는 일 |
|---|---|
| Open 액션 → `GH Auth Refresh.app` | `gh auth refresh` 시작 → Aside에 새 탭 → 코드 입력 → 승인 → 탭 닫기 → 알림 |

## 동작

1. `gh auth refresh`를 TTY 없이 띄운다. 코드는 stderr로 나온다.
2. Aside(`View → Developer → Allow JavaScript from Apple Events` 필요)에 새 탭을 열어 `step.js`를 1초마다 돌린다. 페이지를 보고 한 단계씩만 진행한다.
   - 계정 선택 Continue → 코드 입력 Continue → 조직 SSO 단계는 `skip_sso` Continue로 건너뜀 → **"GitHub CLI" 요청일 때만** Authorize
3. 성공/실패는 알림으로 알린다. 5분 안에 끝나지 않으면 실패로 본다.

- 조직 SSO(예: KRAFTON AI)는 건너뛴다. 그 조직 레포는 이 토큰으로 못 읽는다.
- GitHub에 Aside로 로그인돼 있어야 한다. 로그인 화면이 뜨면 알림을 띄우고 로그인할 때까지 기다린다.
- `gh`가 클립보드에 코드를 복사하므로 실행 후 클립보드가 바뀐다.

## scope

`scopes.txt`에 한 줄에 하나. 삭제 계열(`delete_repo`, `delete:packages`)과 관리자급(`admin:*`, `manage_*`)은 뺐다. 이미 가진 scope는 refresh가 유지한다. 바꾼 뒤 `build.sh`를 다시 돌린다.

토큰 하나에 이 scope들이 붙으므로 `gh`를 쓰는 모든 도구가 같은 권한을 가진다.

## 설치

```bash
tools/gh-auth-refresh/build.sh
```

`~/Applications/GH Auth Refresh.app`이 만들어진다. 처음 실행하면 macOS가 "Aside를 제어하도록 허용" 확인을 한 번 묻는다. 허용한다.

Stream Deck: **System → Open** 액션을 키에 올리고 App/File에 `~/Applications/GH Auth Refresh.app`을 지정한다.
