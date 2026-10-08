// Aside 탭에서 1초마다 실행되는 GitHub 기기 인증 상태 머신. 페이지를 보고 다음 한 단계만 진행하고 상태 문자열을 돌려준다.
// __CODE__는 refresh.sh가 gh가 낸 일회용 코드로 바꾼다.
(() => {
  const code = '__CODE__';
  const path = location.pathname;
  const text = (document.querySelector('main') || document.body).innerText;

  // 같은 단계를 페이지 이동 전에 두 번 누르지 않도록 5초 안에는 다시 누르지 않는다.
  const click = (key, el) => {
    const last = Number(sessionStorage.getItem(key) || 0);
    if (Date.now() - last < 5000) return false;
    sessionStorage.setItem(key, String(Date.now()));
    el.click();
    return true;
  };

  if (location.host !== 'github.com') return 'external:' + location.host;
  if (path === '/login/device/success') return 'success';
  if (path === '/login/device/failure') return 'failure:' + location.search;

  if (path === '/login/device/select_account') {
    click('select', document.querySelector('input[type=submit][value=Continue]'));
    return 'select_account';
  }

  if (path === '/login/device') {
    const first = document.getElementById('user-code-0');
    if (!first) return 'login_required';
    const tries = Number(sessionStorage.getItem('codeTries') || 0);
    if (tries >= 3) return 'failure:code_rejected';
    [0, 1, 2, 3, 5, 6, 7, 8].forEach((n, i) => {
      const el = document.getElementById('user-code-' + n);
      el.focus();
      el.value = code.replace('-', '')[i];
      el.dispatchEvent(new Event('input', { bubbles: true }));
    });
    if (click('code', document.querySelector('input[type=submit][name=commit]'))) {
      sessionStorage.setItem('codeTries', String(tries + 1));
    }
    return 'code';
  }

  if (path === '/login/device/confirmation') {
    // 조직 SSO 단계: 하단의 skip_sso Continue로 건너뛴다.
    const skip = document.querySelector('form input[name=skip_sso]');
    if (skip) {
      click('sso', skip.form.querySelector('input[type=submit]'));
      return 'skip_sso';
    }
    // 최종 승인 단계: 요청 앱이 GitHub CLI일 때만 Authorize를 누른다.
    const authorize = document.querySelector('form[action$="/login/device/authorize"] button[name=authorize][value="1"]');
    if (authorize) {
      if (!text.includes('GitHub CLI')) return 'failure:not_github_cli';
      click('authorize', authorize);
      return 'authorize';
    }
  }

  if (path.startsWith('/login') || path.startsWith('/session')) return 'login_required';
  return 'unknown:' + path;
})()
