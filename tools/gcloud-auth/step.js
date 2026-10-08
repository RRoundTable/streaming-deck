// Aside 탭에서 1초마다 실행되는 구글 로그인 상태 머신. 페이지를 보고 다음 한 단계만 진행하고 상태 문자열을 돌려준다.
// __ACCOUNT__는 login.sh가 gcloud에 설정된 계정으로 바꾼다.
(() => {
  const account = '__ACCOUNT__';
  const path = location.pathname;
  const text = document.body.innerText;

  // 같은 단계를 페이지 이동 전에 두 번 누르지 않도록 5초 안에는 다시 누르지 않는다.
  const click = (key, el) => {
    const last = Number(sessionStorage.getItem(key) || 0);
    if (Date.now() - last < 5000) return false;
    sessionStorage.setItem(key, String(Date.now()));
    el.click();
    return true;
  };

  if (location.host === 'localhost') return 'callback';
  if (location.host !== 'accounts.google.com') return 'external:' + location.host;

  // 재인증 화면: 패스키 쪽으로 길만 열어 둔다(비밀번호 화면 → 다른 방법 시도 → 패스키). 지문은 사람이 댄다.
  // 비밀번호·지문·2단계 인증은 자동으로 못 하므로 사람이 끝낼 때까지 기다린다.
  if (path.includes('/challenge')) {
    const texts = /패스키|passkey/i;
    const others = /휴대|태블릿|phone|tablet|보안 키|security key/i;
    const leaf = els => els.filter(e => !els.some(o => o !== e && e.contains(o)));
    const pick = pred => leaf([...document.querySelectorAll('button,[role=button],[role=link],li,a')].filter(pred))[0];
    // 같은 길을 두 번까지만 시도한다. 사용자가 비밀번호로 가려 해도 계속 뺏지 않는다.
    const attempt = (key, el) => {
      const n = Number(sessionStorage.getItem(key + 'Tries') || 0);
      if (!el || n >= 2) return;
      if (click(key, el)) sessionStorage.setItem(key + 'Tries', String(n + 1));
    };
    if (path.includes('/selection')) {
      attempt('passkey', pick(e => texts.test(e.innerText) && !others.test(e.innerText)));
    } else if (!path.includes('/pk')) {
      attempt('other', pick(e => /다른 방법|Try another way/i.test(e.innerText)));
    }
    return 'login_required';
  }
  if (path.includes('/identifier')) return 'login_required';

  // 동의 단계: Google Cloud SDK 요청일 때만 계속/허용을 누른다. 계정 선택보다 먼저 본다(동의 화면에도 계정 칩이 있다).
  if (path.startsWith('/signin/oauth')) {
    if (!text.includes('Google Cloud SDK')) return 'failure:not_gcloud';
    const labels = ['계속', 'Continue', '허용', 'Allow'];
    const btn = [...document.querySelectorAll('button')].find(b => labels.includes(b.innerText.trim()));
    if (btn) {
      click('consent', btn);
      return 'consent';
    }
    return 'consent_wait';
  }

  // 계정이 여러 개일 때: gcloud 계정을 고른다.
  const item = document.querySelector('[data-identifier="' + account + '"]');
  if (item) {
    click('account', item);
    return 'account';
  }

  return 'unknown:' + path;
})()
