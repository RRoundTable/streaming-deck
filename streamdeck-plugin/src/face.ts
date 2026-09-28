// 키 화면: `sd status --short` 한 줄 → 144×144 SVG data URI. 판단은 sd가 하고 여기서는 모양만 정한다.
//   🎯 32m        → 빨강, "32m" / DEEP
//   ⏰ 블록 종료   → 빨강, "휴식" / 블록 종료
//   📌 75/150m    → 회색, "75" "/150m" / MIT
//   (빈 출력)      → 어두운 회색 "sd" (Start Day 전, Shutdown 후)
const RED = "#E6474C";
const GRAY = "#262626";
const OFF = "#111111";

export type Face = { bg: string; big: string; small?: string; label: string };

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
      return { bg: GRAY, big: "?", label: status.replace(/^! /, "").slice(0, 12) };
  }
}

const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

export function svg({ bg, big, small, label }: Face): string {
  const size = big.length <= 3 ? 56 : big.length <= 5 ? 42 : 30;
  const font = `font-family="-apple-system, 'Apple SD Gothic Neo', Helvetica, sans-serif" fill="#fff" text-anchor="middle"`;
  const body = small
    ? `<text x="72" y="84" ${font} font-weight="700" font-size="${Math.min(size, 46)}">${esc(big)}</text>
       <text x="72" y="120" ${font} font-size="24" opacity="0.8">${esc(small)}</text>`
    : `<text x="72" y="${label ? 82 : 90}" ${font} font-weight="700" font-size="${size}">${esc(big)}</text>`;
  const xml = `<svg xmlns="http://www.w3.org/2000/svg" width="144" height="144" viewBox="0 0 144 144">
    <rect width="144" height="144" fill="${bg}"/>
    ${label ? `<text x="72" y="32" ${font} font-size="18" opacity="0.75">${esc(label)}</text>` : ""}
    ${body}
  </svg>`;
  // 원시 SVG 문자열은 기기에서 안 그려지는 경우가 있어 data URI로 보낸다
  return `data:image/svg+xml;base64,${Buffer.from(xml).toString("base64")}`;
}

