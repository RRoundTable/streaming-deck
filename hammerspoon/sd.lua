-- streaming-deck의 macOS 앱 계층. 로직은 전부 bin/sd에 있고, 여기서는 연결만 한다.
--   ⌃⌥1 / ⌃⌥2 / ⌃⌥3 / ⌃⌥0   bin/sd start-day / deep / deep25 / shutdown → 결과(stdout, 실패 시 stderr)를 알림
--   ⌃⌥2 / ⌃⌥3은 먼저 선택창: bin/sd tasks 후보(MIT leaf 항목)에서 고르거나 새로 입력, Esc는 취소
--   bin/sd status       메뉴 막대(" · " 앞부분만) + 화면 오른쪽 아래 HUD(전체 문구)
--   bin/sd timer        블록 중 HUD는 줄어드는 링 + MM:SS + 완료 조건. 1초마다 다시 그린다
--   HUD는 반투명이다. 끌면 옮겨지고, 오른쪽 아래 모서리를 끌면 크기가 바뀐다. 위치·크기는 hs.settings에 남는다
--   포인터를 올리면 모서리에 손잡이(사선)가 보이고, 모서리 위에서는 진해진다
--   ~/.focus/notify     백그라운드 _guard가 쓴 문구를 알림으로 띄우고 지운다
-- ~/.hammerspoon/init.lua: dofile("<repo>/hammerspoon/sd.lua").start("<repo>")
local M = {}

local HOTKEY_MODS = { "ctrl", "alt" }
local HOTKEYS = { ["1"] = "start-day", ["2"] = "deep", ["3"] = "deep25", ["0"] = "shutdown" }
local CHOOSER_TITLES = { deep = "Deep 50", deep25 = "Deep 25" }  -- 선택창을 먼저 띄우는 명령
local PAD, MARGIN, REFRESH_SEC = 12, 16, 20
local FOCUS_DIR = os.getenv("HOME") .. "/.focus"
local NOTIFY_FILE = FOCUS_DIR .. "/notify"
local RED = { red = 0.90, green = 0.28, blue = 0.30 }  -- 🎯 ⏰
local GRAY = { white = 0.15 }                          -- 📌
local HUD_ALPHA = 0.45                                 -- HUD 배경. 글자는 불투명 + 그림자
local RING, STROKE = 56, 5                             -- 타이머 링 지름·굵기
local FONT_SIZE, TIME_SIZE, RADIUS = 15, 13, 8          -- HUD 치수는 전부 scale을 곱해 쓴다
local GRIP, MIN_SCALE, MAX_SCALE = 16, 0.6, 3          -- 크기 조절 손잡이: 오른쪽 아래 모서리 GRIP pt
local POS_KEY, SCALE_KEY = "streamingDeck.hudPos", "streamingDeck.hudScale"

local sd, menubar, canvas, chooser, ticker, drag, renderHud
local hudText, block = "", nil       -- block = { ends = epoch, total = 초, task = 완료 조건 } (블록 중에만)
local hudPos = hs.settings.get(POS_KEY)  -- 끌어 옮긴 HUD의 왼쪽 위 좌표. 없으면 화면 오른쪽 아래
local scale = hs.settings.get(SCALE_KEY) or 1
local hover                              -- 포인터 위치: nil(HUD 밖) | "hud" | "grip"(크기 조절 모서리)

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

local function styled(text, font, size, align)
  return hs.styledtext.new(text, {
    font = { name = font, size = size },
    color = { white = 1 },
    paragraphStyle = { alignment = align or "left" },
    shadow = { offset = { h = -1, w = 0 }, blurRadius = 2, color = { alpha = 0.6 } },
  })
end

-- 끌어 옮긴 적이 없으면 주 화면 오른쪽 아래. 옮겼으면 그 좌표가 속한 화면(없으면 주 화면) 안으로 밀어 넣는다.
local function hudOrigin(w, h)
  local screen = hs.screen.mainScreen()
  if not hudPos then
    local f = screen:frame()
    return { x = f.x + f.w - w - MARGIN, y = f.y + f.h - h - MARGIN }
  end
  for _, s in ipairs(hs.screen.allScreens()) do
    if hs.geometry.point(hudPos.x, hudPos.y):inside(s:fullFrame()) then screen = s end
  end
  local f = screen:frame()
  return { x = math.max(f.x, math.min(hudPos.x, f.x + f.w - w)),
           y = math.max(f.y, math.min(hudPos.y, f.y + f.h - h)) }
end

local function onGrip(x, y)
  local f = canvas:frame()
  return x > f.w - GRIP and y > f.h - GRIP
end

-- 마우스 버튼을 누르고 있는 동안 HUD가 포인터를 따라간다. 오른쪽 아래 모서리에서 시작하면
-- 왼쪽 위를 고정하고 크기를 바꾼다. 떼면 위치와 크기를 저장한다.
local function startDrag(x, y)
  local from, start, fromScale = canvas:frame(), hs.mouse.absolutePosition(), scale
  local resizing = onGrip(x, y)
  if resizing then hudPos = { x = from.x, y = from.y } end
  drag = hs.timer.doWhile(function()
    if hs.mouse.getButtons().left then return true end
    hs.settings.set(POS_KEY, hudPos)
    hs.settings.set(SCALE_KEY, scale)
    return false
  end, function()
    local now = hs.mouse.absolutePosition()
    local dx, dy = now.x - start.x, now.y - start.y
    if resizing then
      scale = math.max(MIN_SCALE, math.min(fromScale * (from.w + dx) / from.w, MAX_SCALE))
    elseif dx ~= 0 or dy ~= 0 then
      hudPos = { x = from.x + dx, y = from.y + dy }
    end
    renderHud()
  end, 1 / 60)
end

local function onMouse(_, event, _, x, y)
  if event == "mouseDown" then startDrag(x, y); return end
  local now = event ~= "mouseExit" and (onGrip(x, y) and "grip" or "hud") or nil
  if now ~= hover then hover = now; renderHud() end
end

function renderHud()
  if hudText == "" then
    if canvas then canvas:hide() end
    return
  end
  local pad, ringD, stroke, radius = PAD * scale, RING * scale, STROKE * scale, RADIUS * scale
  local color = isFocus(hudText) and RED or GRAY
  local elements = { { type = "rectangle", action = "fill", roundedRectRadii = { xRadius = radius, yRadius = radius },
                       fillColor = { red = color.red, green = color.green, blue = color.blue,
                                     white = color.white, alpha = HUD_ALPHA } } }
  local label = styled(block and block.task or hudText, ".AppleSystemUIFont", FONT_SIZE * scale)
  local size = hs.drawing.getTextDrawingSize(label)
  local h = math.max(size.h, block and ringD or 0) + pad
  local x = pad
  if block then
    local left = math.max(block.ends - os.time(), 0)
    local time = styled(string.format("%02d:%02d", left // 60, left % 60), "Menlo", TIME_SIZE * scale, "center")
    local timeH = hs.drawing.getTextDrawingSize(time).h
    local ring = { type = "arc", action = "stroke", arcRadii = false, strokeWidth = stroke,
                   center = { x = x + ringD / 2, y = h / 2 }, radius = (ringD - stroke) / 2 }
    local function arc(from, strokeColor)  -- 각도는 12시에서 시계 방향
      local e = { startAngle = from, endAngle = 360, strokeColor = strokeColor }
      for k, v in pairs(ring) do e[k] = v end
      return e
    end
    table.insert(elements, arc(0, { white = 1, alpha = 0.25 }))
    table.insert(elements, arc(360 * (1 - left / block.total), { white = 1 }))  -- 남은 만큼만 남는다
    table.insert(elements, { type = "text", text = time,
                             frame = { x = x, y = (h - timeH) / 2, w = ringD, h = timeH } })
    x = x + ringD + pad
  end
  table.insert(elements, { type = "text", text = label,
                           frame = { x = x, y = (h - size.h) / 2, w = size.w + 2, h = size.h } })
  local w = x + size.w + pad
  if hover then
    for _, d in ipairs({ 5, 9, 13 }) do  -- 오른쪽 아래 모서리의 사선 손잡이
      table.insert(elements, { type = "segments", action = "stroke", strokeWidth = 1.5,
                               strokeColor = { white = 1, alpha = hover == "grip" and 1 or 0.4 },
                               coordinates = { { x = w - 3, y = h - 3 - d }, { x = w - 3 - d, y = h - 3 } } })
    end
  end
  if not canvas then
    canvas = hs.canvas.new({ x = 0, y = 0, w = w, h = h })
      :level(hs.canvas.windowLevels.overlay)
      :behavior({ "canJoinAllSpaces", "stationary" })
      :clickActivating(false)
      :canvasMouseEvents(true, false, true, true)
      :mouseCallback(onMouse)
  end
  local at = hudOrigin(w, h)
  canvas:frame({ x = at.x, y = at.y, w = w, h = h })
  canvas:replaceElements(elements)
  canvas:show()
end

local function showHud(text, timer)
  hudText, block = text, timer
  if block then ticker:start() else ticker:stop() end
  renderHud()
end

local function refresh()
  hs.task.new(sd, function(_, out)
    local text = trim(out)
    renderMenubar(text)
    if not text:find("^🎯") then showHud(text); return end
    hs.task.new(sd, function(_, timer)
      local ends, total = timer:match("^(%d+) (%d+)")
      showHud(text, ends and { ends = tonumber(ends), total = tonumber(total), task = text:match(" · (.*)$") or "" })
    end, { "timer" }):start()
  end, { "status" }):start()
end

local function tick()
  if block.ends > os.time() then renderHud() else refresh() end
end

local function run(args)
  hs.task.new(sd, function(code, out, err)
    local msg = trim(code == 0 and out or err)
    if msg ~= "" then notify(msg) end
    refresh()
  end, args):start()
end

-- 후보는 bin/sd tasks가 만든다("작업<TAB>설명", 첫 줄이 기본값). 여기서는 보여주고 거르기만 한다.
-- 목록에 없는 글자를 치면 "＋ 새 작업"이 붙는다. 노트에는 쓰지 않고 start 줄로 로그에만 남는다.
local function chooseTask(cmd)
  hs.task.new(sd, function(code, out, err)
    if code ~= 0 then notify(trim(err)); return end
    local base = {}
    for line in out:gmatch("[^\n]+") do
      local task, sub = line:match("^(.-)\t(.*)$")
      if task and task ~= "" then table.insert(base, { text = task, subText = sub, task = task }) end
    end
    local function filter(query)
      local q = query:gsub("^%s+", ""):gsub("%s+$", "")
      if q == "" then return base end
      local list, exact = {}, false
      for _, c in ipairs(base) do
        if c.task:lower():find(q:lower(), 1, true) then table.insert(list, c) end
        exact = exact or c.task == q
      end
      if not exact then
        table.insert(list, { text = "＋ " .. q, subText = "새 작업 · 로그에만 기록 (MIT 추가는 노트에서 직접)", task = q })
      end
      return list
    end
    if chooser then chooser:delete() end
    chooser = hs.chooser.new(function(choice)
      if choice then run({ cmd, choice.task }) else notify("블록 취소됨") end
    end)
    chooser:placeholderText(CHOOSER_TITLES[cmd] .. " — 이 블록이 끝나면 무엇이 되어 있나?")
    chooser:queryChangedCallback(function(query) chooser:choices(filter(query)) end)
    chooser:choices(base)
    chooser:show()
  end, { "tasks" }):start()
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
    table.insert(M.hotkeys, hs.hotkey.bind(HOTKEY_MODS, key, function()
      if CHOOSER_TITLES[cmd] then chooseTask(cmd) else run({ cmd }) end
    end))
  end
  ticker = hs.timer.new(1, tick)
  M.ticker = ticker
  M.timer = hs.timer.doEvery(REFRESH_SEC, refresh)
  M.watcher = hs.pathwatcher.new(FOCUS_DIR, onFocusDirChange):start()
  -- 전역에 붙잡아 두지 않으면 가비지 컬렉션이 타이머·감시를 멈춘다(init.lua는 반환값을 버린다).
  _G.streamingDeck = M
  refresh()
  return M
end

return M
