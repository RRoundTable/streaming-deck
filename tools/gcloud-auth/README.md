# gcloud-auth

버튼 하나로 로컬과 agent-sandbox VM의 `gcloud auth login --update-adc`를 차례로 끝까지 실행한다. 구글 로그인·동의 화면을 Aside 브라우저에서 대신 진행한다. 끝나면 알림이 뜬다. 양쪽 모두 CLI 자격과 ADC(`application_default_credentials.json`)가 같이 갱신된다.

| 키 | 하는 일 |
|---|---|
| Open 액션 → `GCloud Auth.app` | 로컬 로그인 → VM 로그인 → 알림 |

## 동작

로컬이 먼저다. VM에는 IAP 터널로 ssh하는데 이 터널이 로컬 gcloud 자격을 쓰므로, 로컬 자격이 만료돼 있으면 VM에 들어갈 수 없다. 로컬이 실패하면 VM은 시도하지 않는다.

**로컬**

1. `gcloud auth login --update-adc --quiet`를 TTY 없이 띄운다. 인증 URL은 stdout으로 나온다(`BROWSER=/usr/bin/true`로 gcloud가 직접 브라우저를 열지 않게 한다).
2. 그 URL에 `login_hint=<gcloud에 설정된 계정>`을 붙여 Aside(`View → Developer → Allow JavaScript from Apple Events` 필요)의 새 탭으로 연다. `step.js`가 1초마다 한 단계씩 진행한다.
   - 계정 선택 → 동의 화면(계속/허용, **Google Cloud SDK 요청일 때만**)

**VM (`ssh agent-sandbox`)**

1. VM에서 `gcloud auth login --no-browser --update-adc --quiet`를 ssh로 띄운다. VM에는 브라우저가 없어서 `gcloud auth login --remote-bootstrap="…"` 명령을 출력하고 입력을 기다린다.
2. 그 명령을 로컬에서 실행한다(gcloud가 신뢰 확인을 물으면 `y`로 답한다. VM이 방금 낸 명령이다). 이후 로컬과 같은 방식으로 Aside에서 구글 인증을 진행한다.
3. 로컬 명령이 끝나며 출력하는 `https://localhost…` 한 줄을 VM 프롬프트("Enter the output of the above command")에 넣는다. VM이 그 코드로 로그인과 ADC 갱신을 마친다.

**공통**

- 이미 로그인·동의된 상태면 클릭 없이 바로 끝난다. 로컬 직후 VM 로그인은 같은 Aside 세션이라 구글이 재인증을 다시 묻지 않을 수 있다(로컬이 막 끝난 상태에서 VM까지 11초에 끝나는 것을 확인했다).
- 구글이 재인증(비밀번호·지문·2단계)을 요구하면 Aside를 앞으로 가져오고 알림을 띄운 뒤 사람이 끝낼 때까지 기다린다. 한 번에 5분 안에 끝나지 않으면 실패로 본다.
- 패스키 항목이 인증 방법 목록에 있으면 "다른 방법 시도 → 패스키"까지 스크립트가 눌러 둔다. 이 길은 두 번까지만 시도하고, 비밀번호는 입력하지 않는다. 이 클릭은 화면 문구(`다른 방법`/`패스키`)로 찾으므로 구글이 문구를 바꾸면 동작하지 않는다. 그때는 직접 선택하면 된다.
  - 2026-10 기준 이 계정은 Aside·Safari 모두 인증 방법 목록에 패스키가 없어(비밀번호와 "다른 방법 시도"뿐) 이 클릭이 일어나지 않는다. 사람이 직접 인증한다.

계정은 `gcloud config get account` 값을 쓴다. 다른 계정으로 로그인하려면 먼저 `gcloud config set account <계정>`을 한다. VM 호스트는 `~/.ssh/config`의 `agent-sandbox` 별칭이다.

## 설치

```bash
tools/gcloud-auth/build.sh
```

`~/Applications/GCloud Auth.app`이 만들어진다. 처음 실행하면 macOS가 "Aside를 제어하도록 허용" 확인을 한 번 묻는다. 허용한다.

Stream Deck: **System → Open** 액션을 키에 올리고 App/File에 `~/Applications/GCloud Auth.app`을 지정한다.
