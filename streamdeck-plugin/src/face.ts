// 키 화면: sd 출력 한 줄 → 144×144 SVG data URI. 판단은 sd가 하고 여기서는 모양만 정한다.
// 남은 시간 키 (`sd status --short`):
//   🎯 32m        → 빨강, "32m" / DEEP
//   ⏰ 블록 종료   → 빨강, "휴식" / 블록 종료
//   📌 1/6        → 회색, "1" "/6" / MIT
//   (빈 출력)      → 어두운 회색 "sd" (Start Day 전, Shutdown 후)
// Deep 50·25 키 (같은 출력): 🎯 블록 중이면 빨강 "■ 정지" + 줄어드는 링 + MM:SS(`sd timer`의 끝나는 시각, HUD와 같다), 아니면 회색 "DEEP" + 50/25
// 자리 비움 키 (`sd agenda`, "색 이름 · 남은 시간 ↦길이 | 색 이름 · 남은 시간 ↦길이"), 칸마다 배경색:
//   🔵 주간 싱크 · 42m ↦30m | 🟣 퇴근 · 3h20m ↦14h  → 위 파랑(3시간 미만), 아래 보라(3시간 이상)
//   🟠 퇴근 · 40m ↦2d                              → 주황 한 칸 (가까운 공백이 곧 긴 공백, 준비 시작)
//   🔴 …                                           → 빨강, 지금 넘기기
const RED = "#E6474C";
const GRAY = "#262626";
const OFF = "#111111";
const AMBER = "#B86E00";
const BLUE = "#1A56A8";
const PURPLE = "#6B3FA0";
const AWAY_BG: Record<string, string> = { "🔵": BLUE, "🟣": PURPLE, "🟠": AMBER, "🔴": RED };
const LABEL_EM = 7; // 18px 윗줄에 들어가는 길이 (한글 1, 영문·숫자 0.55)

type Section = { label: string; big: string; bg?: string };
export type Block = { ends: number; total: number }; // `sd timer`: 끝나는 시각(epoch 초), 전체 길이(초)
export type Face = { bg: string; big: string; small?: string; label: string; lower?: Section; ring?: number }; // ring: 남은 비율 0~1

function error(line: string): Face {
  return { bg: GRAY, big: "?", label: line.replace(/^! /, "").slice(0, 12) };
}

const em = (ch: string) => (ch.charCodeAt(0) < 0x80 ? 0.55 : 1);

function fit(text: string, max: number): string {
  let width = 0;
  let cut = "";
  for (const ch of text) {
    width += em(ch);
    if (width > max) return cut.trimEnd() + "…";
    cut += ch;
  }
  return text;
}

// "이름 ↦길이". 길이는 다 보이고 이름을 남는 너비에 맞춰 자른다
function nameWithLength(name: string, length: string): string {
  const tail = ` ↦${length}`;
  return fit(name, LABEL_EM - [...tail].reduce((w, ch) => w + em(ch), 0)) + tail;
}

// "색 이름 · 남은 시간 ↦길이" → [배경, 이름, 남은 시간, 길이]
function away(section: string): [string, string, string, string] | undefined {
  const m = section.match(/^(\S+) (.*) · (\S+) ↦(\S+)$/);
  return m && AWAY_BG[m[1]] ? [AWAY_BG[m[1]], m[2], m[3], m[4]] : undefined;
}

export function awayFace(line: string): Face {
  const sections = line.split(" | ").map(away);
  if (sections.some((s) => !s)) return error(line);
  const [[bg, name, until, length], lower] = sections as [string, string, string, string][];
  if (!lower) return { bg, label: fit(name, LABEL_EM), big: until, small: `↦ ${length}` };
  return {
    bg,
    label: nameWithLength(name, length),
    big: until,
    lower: { bg: lower[0], label: nameWithLength(lower[1], lower[3]), big: lower[2] },
  };
}

export function deepFace(status: string, minutes: number, block?: Block, now = Date.now() / 1000): Face {
  const [icon, ...rest] = status.split(" ");
  if (icon !== "🎯") return { bg: GRAY, label: "DEEP", big: String(minutes) };
  if (!block) return { bg: RED, label: "■ 정지", big: rest.join(" ") };
  const left = Math.max(Math.ceil(block.ends - now), 0);
  const mmss = `${String(Math.floor(left / 60)).padStart(2, "0")}:${String(left % 60).padStart(2, "0")}`;
  return { bg: RED, label: "■ 정지", big: mmss, ring: Math.min(left / block.total, 1) };
}

export function face(status: string): Face {
  const [icon, ...rest] = status.split(" ");
  const text = rest.join(" ");
  switch (icon) {
    case "🎯":
      return { bg: RED, big: text, label: "DEEP" };
    case "⏰":
      return { bg: RED, big: "휴식", label: text };
    case "📌": {
      const [done, target] = text.split("/");
      return target ? { bg: GRAY, big: done, small: `/${target}`, label: "MIT" } : { bg: GRAY, big: text, label: "MIT" };
    }
    case "":
      return { bg: OFF, big: "sd", label: "" };
    default:
      return error(status);
  }
}

const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const RING_R = 56;
const RING_STROKE = 8;

// 12시에서 시작해 시계 방향으로 줄어드는 링: 남은 만큼만 남는다 (HUD와 같다)
function ring(fraction: number): string {
  const circle = (extra: string) =>
    `<circle cx="72" cy="72" r="${RING_R}" fill="none" stroke-width="${RING_STROKE}" stroke="#fff" transform="rotate(-90 72 72)" ${extra}/>`;
  const length = 2 * Math.PI * RING_R;
  return `${circle('opacity="0.25"')}${circle(`stroke-linecap="round" stroke-dasharray="${(length * fraction).toFixed(1)} ${length.toFixed(1)}"`)}`;
}

export function svg({ bg, big, small, label, lower, ring: left }: Face): string {
  const size = big.length <= 3 ? 56 : big.length <= 5 ? 42 : 30;
  const font = `font-family="-apple-system, 'Apple SD Gothic Neo', Helvetica, sans-serif" fill="#fff" text-anchor="middle"`;
  const section = (y: number, s: Section) =>
    `<text x="72" y="${y}" ${font} font-size="18" opacity="0.75">${esc(s.label)}</text>
     <text x="72" y="${y + 32}" ${font} font-weight="700" font-size="${s.big.length <= 5 ? 32 : 26}">${esc(s.big)}</text>`;
  const body = left !== undefined
    ? `${ring(left)}
       <text x="72" y="62" ${font} font-size="16" opacity="0.75">${esc(label)}</text>
       <text x="72" y="92" ${font} font-weight="700" font-size="30">${esc(big)}</text>`
    : lower
    ? `<rect y="72" width="144" height="72" fill="${lower.bg ?? bg}"/>
       ${section(26, { label, big })}
       ${section(98, lower)}`
    : `${label ? `<text x="72" y="32" ${font} font-size="18" opacity="0.75">${esc(label)}</text>` : ""}
       ${
         small
           ? `<text x="72" y="84" ${font} font-weight="700" font-size="${Math.min(size, 46)}">${esc(big)}</text>
              <text x="72" y="120" ${font} font-size="24" opacity="0.8">${esc(small)}</text>`
           : `<text x="72" y="${label ? 82 : 90}" ${font} font-weight="700" font-size="${size}">${esc(big)}</text>`
       }`;
  const xml = `<svg xmlns="http://www.w3.org/2000/svg" width="144" height="144" viewBox="0 0 144 144">
    <rect width="144" height="144" fill="${bg}"/>
    ${body}
  </svg>`;
  // 원시 SVG 문자열은 기기에서 안 그려지는 경우가 있어 data URI로 보낸다
  return `data:image/svg+xml;base64,${Buffer.from(xml).toString("base64")}`;
}

