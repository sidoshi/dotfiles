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
					window_label = label,
					layout = rex.layout.block({
						flavor = "com.superlogical.terminal.shell",
						options = { cwd = dir, initial_input = "nvim .\n" },
					}),
				},
			},
		})
		if cerr ~= nil then
			error(cerr, 0)
		end
		rex.client.queue("session.select", { session_id = s.session_id })
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
rex.bind("cmd+alt+[", "session.previous")
rex.bind("cmd+alt+]", "session.next")

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
