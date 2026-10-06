// 키 화면: sd 출력 한 줄 → 144×144 SVG data URI. 판단은 sd가 하고 여기서는 모양만 정한다.
// 남은 시간 키 (`sd status --short`):
//   🎯 32m        → 빨강, "32m" / DEEP
//   ⏰ 블록 종료   → 빨강, "휴식" / 블록 종료
//   📌 1/6        → 회색, "1" "/6" / MIT
//   (빈 출력)      → 어두운 회색 "sd" (Start Day 전, Shutdown 후)
// 캘린더 키 (`sd agenda`, "아이콘 큰 글자 · 윗줄 · 아랫줄"):
//   🟢 지금 · ~15:00 · 주간 싱크     → 초록, 진행 중
//   ⏳ 42m · 14:00 시작 · 주간 싱크  → 주황, Deep 50이 안 들어감
//   📅 14:00 · 10/2 금 · 주간 싱크   → 파랑
//   🗓 2 · 10월 금 · 미팅 없음       → 어두운 회색
// VM 키 (`sd agents`, 같은 형식):
//   🙋 2 · 내 차례 · 벤치 조사        → 보라, 질문·리뷰할 세션 수와 먼저 볼 세션
//   🏃 3 · 실행 중 · 내 차례 없음     → 초록
//   💤 0 · VM 쉬는 중 · 기획 넘기기   → 주황, 실행 중인 세션이 없음
const RED = "#E6474C";
const GRAY = "#262626";
const OFF = "#111111";
const GREEN = "#0F7A5F";
const AMBER = "#B86E00";
const BLUE = "#1A56A8";
const PURPLE = "#5B3FB8";
const AGENDA_BG: Record<string, string> = { "🟢": GREEN, "⏳": AMBER, "📅": BLUE, "🗓": OFF };
const AGENTS_BG: Record<string, string> = { "🙋": PURPLE, "🏃": GREEN, "💤": AMBER };
const TITLE_SIZE = 20;
const TITLE_EM = 6.5; // 키 너비에 들어가는 제목 길이 (한글 1, 영문·숫자 0.55)

export type Face = { bg: string; big: string; small?: string; smallSize?: number; label: string };

function error(line: string): Face {
  return { bg: GRAY, big: "?", label: line.replace(/^! /, "").slice(0, 12) };
}

function fit(text: string, em: number): string {
  let width = 0;
  let cut = "";
  for (const ch of text) {
    width += ch.charCodeAt(0) < 0x80 ? 0.55 : 1;
    if (width > em) return cut.trimEnd() + "…";
    cut += ch;
  }
  return text;
}

// "아이콘 큰 글자 · 윗줄 · 아랫줄" 한 줄. 아이콘이 배경색을 정한다.
function lineFace(line: string, bgs: Record<string, string>): Face {
  const [icon, ...rest] = line.split(" ");
  const bg = bgs[icon];
  const [big, label, ...title] = rest.join(" ").split(" · ");
  if (!bg || !big || !label) return error(line);
  return { bg, big, label, small: fit(title.join(" · "), TITLE_EM), smallSize: TITLE_SIZE };
}

export const agendaFace = (line: string): Face => lineFace(line, AGENDA_BG);
export const agentsFace = (line: string): Face => lineFace(line, AGENTS_BG);

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

export function svg({ bg, big, small, smallSize = 24, label }: Face): string {
  const size = big.length <= 3 ? 56 : big.length <= 5 ? 42 : 30;
  const font = `font-family="-apple-system, 'Apple SD Gothic Neo', Helvetica, sans-serif" fill="#fff" text-anchor="middle"`;
  const body = small
    ? `<text x="72" y="84" ${font} font-weight="700" font-size="${Math.min(size, 46)}">${esc(big)}</text>
       <text x="72" y="120" ${font} font-size="${smallSize}" opacity="0.8">${esc(small)}</text>`
    : `<text x="72" y="${label ? 82 : 90}" ${font} font-weight="700" font-size="${size}">${esc(big)}</text>`;
  const xml = `<svg xmlns="http://www.w3.org/2000/svg" width="144" height="144" viewBox="0 0 144 144">
    <rect width="144" height="144" fill="${bg}"/>
    ${label ? `<text x="72" y="32" ${font} font-size="18" opacity="0.75">${esc(label)}</text>` : ""}
    ${body}
  </svg>`;
  // 원시 SVG 문자열은 기기에서 안 그려지는 경우가 있어 data URI로 보낸다
  return `data:image/svg+xml;base64,${Buffer.from(xml).toString("base64")}`;
}

