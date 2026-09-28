// streaming-deck 표시 전용 Stream Deck 플러그인 (ADR-005).
// 로직은 bin/sd에 있다. 여기서는 `sd status --short`를 읽어 키 화면을 그리기만 한다.
import streamDeck, { SingletonAction, type KeyDownEvent, type WillAppearEvent } from "@elgato/streamdeck";
import { execFile } from "node:child_process";
import { realpathSync, watch } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { face, svg } from "./face.js";

const POLL_MS = 5_000; // 분 단위 표시라 충분하다. 매번 다시 그려 전송 누락도 덮는다
const FOCUS_DIR = join(homedir(), ".focus");

// 이 파일은 <repo>/streamdeck-plugin/com.rroundtable.sd.sdPlugin/bin/plugin.js.
// streamdeck link가 만든 심볼릭 링크를 따라가 저장소의 bin/sd를 찾는다.
const REPO = resolve(dirname(realpathSync(fileURLToPath(import.meta.url))), "../../..");
const SD = join(REPO, "bin/sd");

function readStatus(): Promise<string> {
  return new Promise((done) => {
    execFile(SD, ["status", "--short"], { timeout: 5_000 }, (err, stdout, stderr) => {
      if (err) {
        streamDeck.logger.error(`sd status 실패: ${stderr || err.message}`);
        done("! sd 오류");
      } else {
        done(stdout.trim());
      }
    });
  });
}

class StatusAction extends SingletonAction {
  override readonly manifestId = "com.rroundtable.sd.status";

  async render(): Promise<void> {
    if (this.actions.length === 0) return;
    const image = svg(face(await readStatus()));
    const sends: Promise<void>[] = [];
    this.actions.forEach((a) => {
      if (a.isKey()) sends.push(a.setImage(image));
    });
    await Promise.all(sends);
  }

  override onWillAppear(_ev: WillAppearEvent): Promise<void> {
    return this.render();
  }

  override onKeyDown(_ev: KeyDownEvent): Promise<void> {
    return this.render();
  }
}

const status = new StatusAction();
streamDeck.actions.registerAction(status);

setInterval(() => void status.render(), POLL_MS);

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
