# gcloud-auth

버튼 하나로 `gcloud auth login --update-adc`를 끝까지 실행한다. 구글 로그인·동의 화면을 Aside 브라우저에서 대신 진행한다. 끝나면 알림이 뜬다. CLI 자격과 ADC(`application_default_credentials.json`)가 같이 갱신된다.

| 키 | 하는 일 |
|---|---|
| Open 액션 → `GCloud Auth.app` | `gcloud auth login` 시작 → Aside에 새 탭 → 계정·동의 → 탭 닫기 → 알림 |

## 동작

1. `gcloud auth login --update-adc --quiet`를 TTY 없이 띄운다. 인증 URL은 stdout으로 나온다(`BROWSER=/usr/bin/true`로 gcloud가 직접 브라우저를 열지 않게 한다).
2. 그 URL에 `login_hint=<gcloud에 설정된 계정>`을 붙여 Aside(`View → Developer → Allow JavaScript from Apple Events` 필요)의 새 탭으로 연다. `step.js`가 1초마다 한 단계씩 진행한다.
   - 계정 선택 → 동의 화면(계속/허용, **Google Cloud SDK 요청일 때만**)
3. 이미 로그인·동의된 상태면 클릭 없이 바로 끝난다(약 10초).
4. 비밀번호·2단계 인증 화면이 뜨면 자동으로 할 수 없어서 알림을 띄우고 사람이 끝낼 때까지 기다린다. 5분 안에 끝나지 않으면 실패로 본다.

계정은 `gcloud config get account` 값을 쓴다. 다른 계정으로 로그인하려면 먼저 `gcloud config set account <계정>`을 한다.

## 설치

```bash
tools/gcloud-auth/build.sh
```

`~/Applications/GCloud Auth.app`이 만들어진다. 처음 실행하면 macOS가 "Aside를 제어하도록 허용" 확인을 한 번 묻는다. 허용한다.

Stream Deck: **System → Open** 액션을 키에 올리고 App/File에 `~/Applications/GCloud Auth.app`을 지정한다.
