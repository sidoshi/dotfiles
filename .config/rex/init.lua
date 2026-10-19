local terminal = "com.superlogical.terminal"
local passthrough = { nvim = true, vim = true, fzf = true }

local function focused_block()
	local view = rex.session.view({})
	if not view then
		return nil
	end
	for _, w in ipairs(view.windows) do
		if w.window_id == view.active_window_id then
			return w.focused_block_id
		end
	end
end

-- ctrl+hjkl: nvim/fzf get the key; otherwise move between panes.
-- At the layout edge the key falls through to the shell (ctrl+l still clears).
local function navigate(direction)
	return function(ctx)
		local p = rex.block.call(terminal, "process", { block_id = ctx.block_id })
		if p and p.foreground and passthrough[p.foreground.name] then
			return false
		end
		local before = focused_block()
		rex.session.focus_direction({ direction = direction })
		return before ~= focused_block()
	end
end

for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+" .. key, navigate(dir))
end

-- Option sends Meta (ESC prefix) like Ghostty's macos-option-as-alt.
for _, key in ipairs({ "j", "k" }) do
	rex.bind("alt+" .. key, function(ctx)
		rex.block.call(terminal, "write", { block_id = ctx.block_id, data = "\27" .. key })
		return true
	end)
end

rex.action({
	name = "project",
	title = "Open Project",
	run = function(ctx, args)
		local dir = (args.dir or ""):gsub("/+$", "")
		if dir == "" then
			error("project: dir is required", 0)
		end
		local label = dir:match("([^/]+)$")

		local list, err = rex.call("session.list")
		if err ~= nil then
			error(err, 0)
		end
		for _, s in ipairs(list.sessions) do
			if s.label == label then
				rex.client.queue("session.select", { session_id = s.session_id })
				return { session_id = s.session_id, created = false }
			end
		end

		local s, cerr = rex.call("session.create", {
			label = label,
			initial_windows = {
				{
					window_label = "nvim",
					layout = rex.layout.block({
						flavor = "com.superlogical.terminal.shell",
						options = { cwd = dir, initial_input = "nvim .\n" },
					}),
				},
				{
					window_label = "claude",
					layout = rex.layout.block({
						flavor = "com.superlogical.terminal.shell",
						options = { cwd = dir, initial_input = "claude\n" },
					}),
				},
			},
		})
		if cerr ~= nil then
			error(cerr, 0)
		end
		rex.client.queue("session.select", {
			session_id = s.session_id,
			window_id = s.initial_windows[1].window_id,
		})
		return { session_id = s.session_id, created = true }
	end,
})

local function picker(name, title, mode)
	rex.action({
		name = name,
		title = title,
		run = function(ctx)
			local _, err = rex.session.new_window({
				window_label = mode,
				focus = true,
				layout = rex.layout.block({
					flavor = "com.superlogical.terminal.shell",
					options = { command = { os.getenv("HOME") .. "/.config/rex/picker", mode, ctx.client_id } },
				}),
			})
			if err ~= nil then
				error(err, 0)
			end
		end,
	})
end

picker("pick_project", "Pick Project…", "projects")
picker("pick_session", "Pick Session…", "sessions")

rex.bind("cmd+p", "pick_project")

-- alt+q: close the session after a confirm dialog.
rex.bind("alt+q", function(ctx)
	local label = "this session"
	local list = rex.call("session.list")
	for _, s in ipairs(list and list.sessions or {}) do
		if s.session_id == ctx.session_id then
			label = s.label
		end
	end
	local r = rex.exec({
		"osascript",
		"-e",
		'tell application "Rex Beta" to display dialog "Close session '
			.. label
			.. '?" buttons {"Cancel", "Close"} default button "Close" cancel button "Cancel" with icon caution',
	})
	if not r or not r.ok then
		return true
	end
	rex.call("session.destroy", { session_id = ctx.session_id })
	return true
end)
-- Cycle keys: ctrl acts on tabs in the session, alt acts on sessions.
rex.bind("alt+tab", "session.next")
rex.bind("alt+shift+tab", "session.previous")
rex.bind("alt+[", "session.previous")
rex.bind("alt+]", "session.next")

-- ctrl+tab / ctrl+shift+tab: cycle tabs in the current session only.
-- The app default follows the sidebar, which lists tabs of all sessions.
-- These are actions, not key handlers, because only an action can queue session.select.
local function cycle_tab(name, title, step)
	rex.action({
		name = name,
		title = title,
		run = function(ctx)
			local view = rex.session.view({})
			if not view or #view.windows < 2 then
				return
			end
			local activeIndex = 1
			for index, w in ipairs(view.windows) do
				if w.window_id == view.active_window_id then
					activeIndex = index
				end
			end
			local nextIndex = (activeIndex - 1 + step) % #view.windows + 1
			rex.client.queue("session.select", {
				session_id = ctx.session_id,
				window_id = view.windows[nextIndex].window_id,
			})
		end,
	})
end

cycle_tab("session_tab_next", "Next Tab in Session", 1)
cycle_tab("session_tab_previous", "Previous Tab in Session", -1)

rex.bind("ctrl+tab", "session_tab_next")
rex.bind("ctrl+shift+tab", "session_tab_previous")
rex.bind("ctrl+[", "client.tab.previous")
rex.bind("ctrl+]", "client.tab.next")

local shells = { zsh = true, ["-zsh"] = true, bash = true, sh = true, fish = true }

-- cmd+w: close the pane, but ask first when a program other than the shell runs in it.
rex.bind("cmd+w", function(ctx)
	local p = rex.block.call(terminal, "process", { block_id = ctx.block_id })
	local fg = p and p.foreground
	if fg and not shells[fg.argv0 or fg.name] then
		local r = rex.exec({
			"osascript",
			"-e",
			'tell application "Rex Beta" to display dialog "Close the pane running '
				.. (fg.argv0 or fg.name)
				.. '?" buttons {"Cancel", "Close"} default button "Close" cancel button "Cancel" with icon caution',
		})
		if not r or not r.ok then
			return true
		end
	end
	rex.call("block.close", { session_id = ctx.session_id, block_id = ctx.block_id })
	return true
end)
