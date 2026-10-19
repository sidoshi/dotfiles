local terminal = "com.superlogical.terminal"
local passthrough = { nvim = true, vim = true, fzf = true }

local function focused_block()
  local view = rex.session.view{}
  if not view then return nil end
  for _, w in ipairs(view.windows) do
    if w.window_id == view.active_window_id then return w.focused_block_id end
  end
end

-- ctrl+hjkl: nvim/fzf get the key; otherwise move between panes.
-- At the layout edge the key falls through to the shell (ctrl+l still clears).
local function navigate(direction)
  return function(ctx)
    local p = rex.block.call(terminal, "process", { block_id = ctx.block_id })
    if p and p.foreground and passthrough[p.foreground.name] then return false end
    local before = focused_block()
    rex.session.focus_direction{ direction = direction }
    return before ~= focused_block()
  end
end

for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+" .. key, navigate(dir))
end
