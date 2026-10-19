-- Run with `rex do --all notify.lua`: macOS notification when a program in
-- any session is blocked or done, unless Rex is the frontmost app.
local function rex_frontmost()
  local front = rex.exec({ "lsappinfo", "front" })
  if not front.ok then return false end
  local r = rex.exec({ "lsappinfo", "info", "-only", "name", (front.stdout:gsub("%s+$", "")) })
  return r.ok and r.stdout:find('="Rex', 1, true) ~= nil
end

local function session_label(id)
  local list = rex.call("session.list")
  for _, s in ipairs(list and list.sessions or {}) do
    if s.session_id == id then return s.label end
  end
  return "Rex"
end

rex.on("terminal.program_status_changed", function(ctx, ev)
  local r = ev.record
  if ev.reason ~= "report" or not r then return end
  if r.state ~= "blocked" and r.state ~= "done" then return end
  if rex_frontmost() then return end

  local title = session_label(ctx.session_id)
  local body = r.msg or r.state
  if r.app then body = r.app .. ": " .. body end
  rex.exec({
    "osascript", "-e", "on run argv",
    "-e", "display notification (item 2 of argv) with title (item 1 of argv)",
    "-e", "end run", title, body,
  })
end)
