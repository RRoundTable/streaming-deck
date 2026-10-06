// streaming-deck Stream Deck 플러그인 (ADR-005, ADR-006, ADR-009, ADR-011).
// 로직은 bin/sd에 있다. 여기서는 sd 출력 한 줄을 읽어 키 화면을 그리기만 한다.
//   남은 시간 키:      `sd status --short`, 5초마다. 누르면 새로고침
//   Deep 50·25 키:     같은 출력으로 블록 중이면 "■ 정지". 누르면 Hammerspoon의 ⌃⌥2/⌃⌥3과 같은 동작(선택창 또는 정지)
//   자리 비움 키:      `sd agenda`, 1분마다. 누르면 `sd calendar`(Google Calendar 오늘 보기 + 동기화)
import streamDeck, { SingletonAction, type KeyDownEvent, type WillAppearEvent } from "@elgato/streamdeck";
import { execFile } from "node:child_process";
import { realpathSync, watch } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { awayFace, deepFace, face, svg, type Face } from "./face.js";

const STATUS_POLL_MS = 5_000; // 분 단위 표시라 충분하다. 매번 다시 그려 전송 누락도 덮는다
const AGENDA_POLL_MS = 60_000; // 남은 분이 바뀌는 주기. sd가 그때마다 일정도 다시 읽는다
const FOCUS_DIR = join(homedir(), ".focus");

// 이 파일은 <repo>/streamdeck-plugin/com.rroundtable.sd.sdPlugin/bin/plugin.js.
// streamdeck link가 만든 심볼릭 링크를 따라가 저장소의 bin/sd를 찾는다.
const REPO = resolve(dirname(realpathSync(fileURLToPath(import.meta.url))), "../../..");
const SD = join(REPO, "bin/sd");

function sd(args: string[]): Promise<string> {
  return new Promise((done) => {
    execFile(SD, args, { timeout: 5_000 }, (err, stdout, stderr) => {
      if (err) {
        streamDeck.logger.error(`sd ${args.join(" ")} 실패: ${stderr || err.message}`);
        done("! sd 오류");
      } else {
        done(stdout.trim());
      }
    });
  });
}

// Deep 키의 동작은 Hammerspoon에 있다(선택창, 블록 중이면 정지). URL 이벤트로 단축키와 같은 함수를 부른다.
function hammerspoon(cmd: string): Promise<void> {
  return new Promise((done) => {
    execFile("open", ["-g", `hammerspoon://sd-key?cmd=${cmd}`], (err) => {
      if (err) streamDeck.logger.error(`hammerspoon sd-key ${cmd} 실패: ${err.message}`);
      done();
    });
  });
}

// sd 출력 한 줄을 키에 그리는 액션. press가 있으면 누를 때 먼저 부른다.
class SdKey extends SingletonAction {
  constructor(
    override readonly manifestId: string,
    readonly args: string[],
    private readonly toFace: (line: string) => Face,
    private readonly press?: () => Promise<unknown>,
  ) {
    super();
  }

  async render(): Promise<void> {
    if (this.actions.length === 0) return;
    await this.draw(await sd(this.args));
  }

  // 같은 sd 출력을 쓰는 키끼리 한 번 읽어 나눠 그린다
  async draw(line: string): Promise<void> {
    const image = svg(this.toFace(line));
    const sends: Promise<void>[] = [];
    this.actions.forEach((a) => {
      if (a.isKey()) sends.push(a.setImage(image));
    });
    await Promise.all(sends);
  }

  override onWillAppear(_ev: WillAppearEvent): Promise<void> {
    return this.render();
  }

  override async onKeyDown(_ev: KeyDownEvent): Promise<void> {
    if (this.press) await this.press();
    await this.render();
  }
}

const status = new SdKey("com.rroundtable.sd.status", ["status", "--short"], face);
const deep50 = new SdKey("com.rroundtable.sd.deep50", status.args, (l) => deepFace(l, 50), () => hammerspoon("deep"));
const deep25 = new SdKey("com.rroundtable.sd.deep25", status.args, (l) => deepFace(l, 25), () => hammerspoon("deep25"));
const statusKeys = [status, deep50, deep25];
async function renderStatusKeys(): Promise<void> {
  if (statusKeys.every((k) => k.actions.length === 0)) return;
  const line = await sd(status.args);
  await Promise.all(statusKeys.map((k) => k.draw(line)));
}
// UUID는 캘린더 키(adr/006) 때 것을 그대로 써서 이미 놓인 키가 그대로 바뀐다
const away = new SdKey("com.rroundtable.sd.calendar", ["agenda"], awayFace, () => sd(["calendar"]));
statusKeys.forEach((k) => streamDeck.actions.registerAction(k));
streamDeck.actions.registerAction(away);

setInterval(() => void renderStatusKeys(), STATUS_POLL_MS);
setInterval(() => void away.render(), AGENDA_POLL_MS);

// 블록 시작·종료·Shutdown은 ~/.focus/state.json을, 캘린더 읽기 앱은 ~/.focus/agenda.tsv를 바꾼다.
// 바로 반영하되 연속 변경은 한 번으로 묶는다.
let pending: NodeJS.Timeout | undefined;
try {
  watch(FOCUS_DIR, () => {
    clearTimeout(pending);
    pending = setTimeout(() => {
      void renderStatusKeys();
      void away.render();
    }, 300);
  });
} catch (err) {
  streamDeck.logger.warn(`~/.focus 감시 실패, 주기 갱신만 사용: ${err}`);
}

streamDeck.logger.info(`sd: ${SD}`);
streamDeck.connect();
