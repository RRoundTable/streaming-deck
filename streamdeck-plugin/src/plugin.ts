// streaming-deck Stream Deck 플러그인 (ADR-005, ADR-006, ADR-007).
// 로직은 bin/sd에 있다. 여기서는 sd 출력 한 줄을 읽어 키 화면을 그리기만 한다.
//   남은 시간 키: `sd status --short`, 5초마다. 누르면 새로고침
//   캘린더 키:    `sd agenda`, 1분마다. 누르면 `sd calendar`(Google Calendar 오늘 보기)
//   VM 키:        `sd agents`, 1분마다. 누르면 새로고침 (sd는 VM을 45초 안에 다시 읽지 않는다)
import streamDeck, { SingletonAction, type KeyDownEvent, type WillAppearEvent } from "@elgato/streamdeck";
import { execFile } from "node:child_process";
import { realpathSync, watch } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { agendaFace, agentsFace, face, svg, type Face } from "./face.js";

const STATUS_POLL_MS = 5_000; // 분 단위 표시라 충분하다. 매번 다시 그려 전송 누락도 덮는다
const AGENDA_POLL_MS = 60_000; // 남은 분이 바뀌는 주기. sd가 그때마다 일정도 다시 읽는다
const AGENTS_POLL_MS = 60_000; // sd가 VM을 45초마다만 읽으므로 더 자주 그려도 같다
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

// sd 출력 한 줄을 키에 그리는 액션. press가 있으면 누를 때 그 sd 명령을 먼저 부른다.
class SdKey extends SingletonAction {
  constructor(
    override readonly manifestId: string,
    private readonly args: string[],
    private readonly toFace: (line: string) => Face,
    private readonly press?: string[],
  ) {
    super();
  }

  async render(): Promise<void> {
    if (this.actions.length === 0) return;
    const image = svg(this.toFace(await sd(this.args)));
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
    if (this.press) await sd(this.press);
    await this.render();
  }
}

const status = new SdKey("com.rroundtable.sd.status", ["status", "--short"], face);
const calendar = new SdKey("com.rroundtable.sd.calendar", ["agenda"], agendaFace, ["calendar"]);
streamDeck.actions.registerAction(status);
const agents = new SdKey("com.rroundtable.sd.agents", ["agents"], agentsFace);
streamDeck.actions.registerAction(calendar);
streamDeck.actions.registerAction(agents);

setInterval(() => void status.render(), STATUS_POLL_MS);
setInterval(() => void calendar.render(), AGENDA_POLL_MS);
setInterval(() => void agents.render(), AGENTS_POLL_MS);

// 블록 시작·종료·Shutdown은 ~/.focus/state.json을 바꾼다. 바로 반영하되 연속 변경은 한 번으로 묶는다.
let pending: NodeJS.Timeout | undefined;
try {
  watch(FOCUS_DIR, () => {
    clearTimeout(pending);
    pending = setTimeout(() => void status.render(), 300);
  });
} catch (err) {
  streamDeck.logger.warn(`~/.focus 감시 실패, 주기 갱신만 사용: ${err}`);
}

streamDeck.logger.info(`sd: ${SD}`);
streamDeck.connect();
