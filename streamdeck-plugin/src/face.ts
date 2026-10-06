// 키 화면: sd 출력 한 줄 → 144×144 SVG data URI. 판단은 sd가 하고 여기서는 모양만 정한다.
// 남은 시간 키 (`sd status --short`):
//   🎯 32m        → 빨강, "32m" / DEEP
//   ⏰ 블록 종료   → 빨강, "휴식" / 블록 종료
//   📌 1/6        → 회색, "1" "/6" / MIT
//   (빈 출력)      → 어두운 회색 "sd" (Start Day 전, Shutdown 후)
// 자리 비움 키 (`sd agenda`, "색 이름 · 남은 시간 ↦길이 | 이름 · 남은 시간 ↦길이"):
//   ⚪ 주간 싱크 · 42m ↦30m | 퇴근 · 3h20m ↦14h  → 어두운 회색, 위아래 두 칸 (가까운 공백, 긴 공백)
//   🟠 퇴근 · 40m ↦2d                           → 주황, 한 칸 (가까운 공백이 곧 긴 공백)
//   🔴 …                                        → 빨강, 지금 넘기기
const RED = "#E6474C";
const GRAY = "#262626";
const OFF = "#111111";
const AMBER = "#B86E00";
const AWAY_BG: Record<string, string> = { "⚪": GRAY, "🟠": AMBER, "🔴": RED };
const LABEL_EM = 7; // 18px 윗줄에 들어가는 길이 (한글 1, 영문·숫자 0.55)

type Section = { label: string; big: string };
export type Face = { bg: string; big: string; small?: string; label: string; lower?: Section };

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

// "이름 · 남은 시간 ↦길이" → [이름, 남은 시간, 길이]
function away(section: string): [string, string, string] | undefined {
  const m = section.match(/^(.*) · (\S+) ↦(\S+)$/);
  return m ? [m[1], m[2], m[3]] : undefined;
}

export function awayFace(line: string): Face {
  const [icon, ...rest] = line.split(" ");
  const bg = AWAY_BG[icon];
  const sections = rest.join(" ").split(" | ").map(away);
  if (!bg || sections.some((s) => !s)) return error(line);
  const [[name, until, length], lower] = sections as [string, string, string][];
  if (!lower) return { bg, label: fit(name, LABEL_EM), big: until, small: `↦ ${length}` };
  return {
    bg,
    label: nameWithLength(name, length),
    big: until,
    lower: { label: nameWithLength(lower[0], lower[2]), big: lower[1] },
  };
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

export function svg({ bg, big, small, label, lower }: Face): string {
  const size = big.length <= 3 ? 56 : big.length <= 5 ? 42 : 30;
  const font = `font-family="-apple-system, 'Apple SD Gothic Neo', Helvetica, sans-serif" fill="#fff" text-anchor="middle"`;
  const section = (y: number, s: Section) =>
    `<text x="72" y="${y}" ${font} font-size="18" opacity="0.75">${esc(s.label)}</text>
     <text x="72" y="${y + 32}" ${font} font-weight="700" font-size="${s.big.length <= 5 ? 32 : 26}">${esc(s.big)}</text>`;
  const body = lower
    ? `${section(26, { label, big })}
       <line x1="16" y1="74" x2="128" y2="74" stroke="#fff" stroke-opacity="0.3" stroke-width="2"/>
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

