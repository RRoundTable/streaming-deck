-- 화면 오른쪽 아래에 `bin/sd status` 한 줄을 항상 위에 띄운다.
-- 출력이 없으면(Shutdown 후 등) 숨긴다. 클릭은 아래 창으로 통과한다.
-- ~/.hammerspoon/init.lua: dofile("<repo>/hammerspoon/sd_hud.lua").start("<repo>")
local M = {}

local PAD, MARGIN, REFRESH_SEC = 12, 16, 20
local COLORS = {
  focus = { red = 0.90, green = 0.28, blue = 0.30, alpha = 0.90 },  -- 🎯 ⏰
  day   = { white = 0.15, alpha = 0.80 },                          -- 📌
}

local canvas

local function render(text)
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
  canvas[1] = {
    type = "rectangle",
    roundedRectRadii = { xRadius = 8, yRadius = 8 },
    fillColor = text:find("^📌") and COLORS.day or COLORS.focus,
  }
  canvas[2] = { type = "text", text = styled, frame = { x = PAD, y = PAD / 2, w = size.w + 2, h = size.h } }
  canvas:show()
end

function M.start(repo)
  local sd = repo .. "/bin/sd"
  local function refresh()
    hs.task.new(sd, function(_, out)
      render(((out or ""):gsub("%s+$", "")))
    end, { "status" }):start()
  end
  refresh()
  -- 참조를 M에 보관해야 가비지 컬렉션으로 멈추지 않는다.
  M.timer = hs.timer.doEvery(REFRESH_SEC, refresh)
  M.watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.focus", refresh):start()
  return M
end

return M
