-- streaming-deck의 macOS 앱 계층. 로직은 전부 bin/sd에 있고, 여기서는 연결만 한다.
--   ⌃⌥1 / ⌃⌥2 / ⌃⌥0   bin/sd start-day / deep / shutdown → 결과(stdout, 실패 시 stderr)를 알림
--   bin/sd status       메뉴 막대(" · " 앞부분만) + 화면 오른쪽 아래 HUD(전체 문구)
--   ~/.focus/notify     백그라운드 _guard가 쓴 문구를 알림으로 띄우고 지운다
-- ~/.hammerspoon/init.lua: dofile("<repo>/hammerspoon/sd.lua").start("<repo>")
local M = {}

local HOTKEY_MODS = { "ctrl", "alt" }
local HOTKEYS = { ["1"] = "start-day", ["2"] = "deep", ["0"] = "shutdown" }
local PAD, MARGIN, REFRESH_SEC = 12, 16, 20
local FOCUS_DIR = os.getenv("HOME") .. "/.focus"
local NOTIFY_FILE = FOCUS_DIR .. "/notify"
local RED = { red = 0.90, green = 0.28, blue = 0.30, alpha = 0.90 }  -- 🎯 ⏰
local GRAY = { white = 0.15, alpha = 0.80 }                          -- 📌

local sd, menubar, canvas

local function trim(s) return ((s or ""):gsub("%s+$", "")) end
local function isFocus(text) return text:find("^📌") == nil end

local function notify(text)
  hs.notify.new({ title = "sd", informativeText = text }):send()
end

local function renderMenubar(text)
  if text == "" then
    menubar:removeFromMenuBar()
    return
  end
  menubar:returnToMenuBar()
  local short = text:match("^(.-) · ") or text
  menubar:setTitle(hs.styledtext.new(short, isFocus(text) and { color = RED } or {}))
  menubar:setMenu({ { title = text, disabled = true } })
end

local function renderHud(text)
  if text == "" then
    if canvas then canvas:hide() end
    return
  end
  local styled = hs.styledtext.new(text, {
    font = { name = ".AppleSystemUIFont", size = 15 },
    color = { white = 1 },
  })
  local size = hs.drawing.getTextDrawingSize(styled)
  local screen = hs.screen.mainScreen():frame()
  local w, h = size.w + PAD * 2, size.h + PAD
  local frame = { x = screen.x + screen.w - w - MARGIN, y = screen.y + screen.h - h - MARGIN, w = w, h = h }
  if not canvas then
    canvas = hs.canvas.new(frame)
      :level(hs.canvas.windowLevels.overlay)
      :behavior({ "canJoinAllSpaces", "stationary" })
  end
  canvas:frame(frame)
  canvas[1] = { type = "rectangle", roundedRectRadii = { xRadius = 8, yRadius = 8 },
                fillColor = isFocus(text) and RED or GRAY }
  canvas[2] = { type = "text", text = styled, frame = { x = PAD, y = PAD / 2, w = size.w + 2, h = size.h } }
  canvas:show()
end

local function refresh()
  hs.task.new(sd, function(_, out)
    local text = trim(out)
    renderMenubar(text)
    renderHud(text)
  end, { "status" }):start()
end

local function run(cmd)
  hs.task.new(sd, function(code, out, err)
    local msg = trim(code == 0 and out or err)
    if msg ~= "" then notify(msg) end
    refresh()
  end, { cmd }):start()
end

local function onFocusDirChange()
  local f = io.open(NOTIFY_FILE)
  if f then
    local msg = trim(f:read("a"))
    f:close()
    os.remove(NOTIFY_FILE)
    if msg ~= "" then notify(msg) end
  end
  refresh()
end

function M.start(repo)
  sd = repo .. "/bin/sd"
  hs.menuIcon(false)  -- 노치 옆 공간 절약. 설정 다시 읽기: Hammerspoon 앱을 열어 콘솔에서 hs.reload()
  menubar = hs.menubar.new()
  M.hotkeys = {}
  for key, cmd in pairs(HOTKEYS) do
    table.insert(M.hotkeys, hs.hotkey.bind(HOTKEY_MODS, key, function() run(cmd) end))
  end
  M.timer = hs.timer.doEvery(REFRESH_SEC, refresh)
  M.watcher = hs.pathwatcher.new(FOCUS_DIR, onFocusDirChange):start()
  -- 전역에 붙잡아 두지 않으면 가비지 컬렉션이 타이머·감시를 멈춘다(init.lua는 반환값을 버린다).
  _G.streamingDeck = M
  refresh()
  return M
end

return M
