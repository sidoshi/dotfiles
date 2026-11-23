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

-- Option sends Meta (ESC prefix).
for _, key in ipairs({ "j", "k" }) do
	rex.bind("alt+" .. key, function(ctx)
		rex.block.call(terminal, "write", { block_id = ctx.block_id, data = "\27" .. key })
		return true
	end)
end

-- The nvim and lazygit floating panes: x, y, width, height as fractions of the tab.
-- 96% of each, in the center.
local floatingPaneBounds = { 0.02, 0.02, 0.96, 0.96 }

-- A new project gets one minimized floating pane for each entry.
-- The label is how cmd+alt+n and cmd+alt+g find their pane.
local floatingPanes = {
	{ label = "nvim", command = "nvim ." },
	{ label = "lazygit", command = "lazygit" },
}

rex.action({
	name = "project",
	title = "Open Project",
	run = function(ctx, args)
		local dir = (args.dir or ""):gsub("/+$", "")
		if dir == "" then
			error("project: dir is required", 0)
		end
		local label = dir:match("([^/]+)$")
		local agent = args.agent or "claude"
		if agent ~= "claude" and agent ~= "pi" then
			error("project: agent must be claude or pi", 0)
		end

		local list, err = rex.call("session.list")
		if err ~= nil then
			error(err, 0)
		end
		for _, s in ipairs(list.sessions) do
			if s.label == label then
				if agent == "claude" then
					rex.client.queue("session.select", { session_id = s.session_id })
					return { session_id = s.session_id, created = false }
				end

				rex.call("session.attach", { session_id = s.session_id })
				local view = rex.session.view({ session_id = s.session_id })
				for _, w in ipairs(view and view.windows or {}) do
					if w.label == "pi" then
						rex.client.queue("session.select", { session_id = s.session_id, window_id = w.window_id })
						return { session_id = s.session_id, created = false }
					end
				end

				local w, werr = rex.session.new_window({
					session_id = s.session_id,
					window_label = "pi",
					focus = false,
					layout = rex.layout.block({
						flavor = "com.superlogical.terminal.shell",
						options = { cwd = dir, initial_input = "pi\n" },
					}),
				})
				if werr ~= nil then
					error(werr, 0)
				end
				rex.client.queue("session.select", { session_id = s.session_id, window_id = w.window_id })
				return { session_id = s.session_id, created = false }
			end
		end

		local s, cerr = rex.call("session.create", {
			label = label,
			initial_windows = {
				-- One tab with only the agent. nvim and lazygit are added below as minimized floating panes.
				-- The tab has the agent's name, so the search for a "pi" tab above still finds it.
				{
					window_label = agent,
					layout = rex.layout.block({
						flavor = "com.superlogical.terminal.shell",
						options = { cwd = dir, initial_input = agent .. "\n" },
					}),
				},
			},
		})
		if cerr ~= nil then
			error(cerr, 0)
		end

		-- nvim and lazygit start in minimized floating panes.
		-- cmd+alt+n and cmd+alt+g show them and hide them again.
		-- Lua can only change a session it is attached to.
		rex.call("session.attach", { session_id = s.session_id })
		for _, floatingPane in ipairs(floatingPanes) do
			local layer, layerError = rex.call("session.new_layer", {
				session_id = s.session_id,
				window_id = s.initial_windows[1].window_id,
				bounds = floatingPaneBounds,
				focus = false,
				layout = rex.layout.block({
					flavor = "com.superlogical.terminal.shell",
					label = floatingPane.label,
					options = { cwd = dir, initial_input = floatingPane.command .. "\n" },
				}),
			})
			if layerError ~= nil then
				error(layerError, 0)
			end
			local _, minimizeError = rex.call("session.set_layer_state", {
				session_id = s.session_id,
				layer_id = layer.layer_id,
				state = "minimized",
			})
			if minimizeError ~= nil then
				error(minimizeError, 0)
			end
		end

		rex.client.queue("session.select", {
			session_id = s.session_id,
			window_id = s.initial_windows[1].window_id,
		})
		return { session_id = s.session_id, created = true }
	end,
})

-- The picker asks its question in the command palette with rex.ui.pick.
-- The list has the open sessions first, then the projects that are not open.
-- In each of the two groups, the items picked most recently come first.
-- The icon shows the type: folder for a project, terminal for a session that is not a project.
-- The detail text "active" shows that a session is open.
-- A project that is already open is selected, not created again. The "project" action does that.

-- Rex does not record when a session was last used, so the picker keeps its own list of
-- picked labels in this file, most recent first, one label per line.
local recentDirectory = os.getenv("HOME") .. "/.local/state/rex"
local recentPath = recentDirectory .. "/picker_recent"

local function project_picker(name, title, agent)
	rex.action({
		name = name,
		title = title,
		run = function(ctx)
			-- (/N) keeps only directories, and gives no error when a parent directory is absent.
			local listing = rex.exec({ "zsh", "-c", "print -l ~/forto/*(/N) ~/gh/*(/N) ~/dotfiles" })
			if not listing or not listing.ok then
				error("pick project: cannot list the project directories", 0)
			end
			local list, err = rex.call("session.list")
			if err ~= nil then
				error(err, 0)
			end

			local projectDirs = {}
			local projectDirByLabel = {}
			for dir in listing.stdout:gmatch("[^\n]+") do
				table.insert(projectDirs, dir)
				projectDirByLabel[dir:match("([^/]+)$")] = dir
			end

			-- Step 1: make one item for each label, and record the default order of the labels.
			local itemByLabel = {}
			local isActiveLabel = {}
			local defaultLabels = {}
			local currentLabel = nil
			for _, s in ipairs(list.sessions) do
				if s.session_id == ctx.session_id then
					currentLabel = s.label
				end
				local projectDir = projectDirByLabel[s.label]
				if projectDir then
					itemByLabel[s.label] = { id = projectDir, title = s.label, icon = "folder", detail = "active" }
				else
					itemByLabel[s.label] = { id = s.session_id, title = s.label, icon = "terminal", detail = "active" }
				end
				isActiveLabel[s.label] = true
				table.insert(defaultLabels, s.label)
			end
			for _, dir in ipairs(projectDirs) do
				local label = dir:match("([^/]+)$")
				if not itemByLabel[label] then
					itemByLabel[label] = { id = dir, title = label, icon = "folder" }
					table.insert(defaultLabels, label)
				end
			end

			-- Step 2: read the labels picked before, most recent first.
			local recentLabels = {}
			local recentFile = io.open(recentPath, "r")
			if recentFile then
				for line in recentFile:lines() do
					table.insert(recentLabels, line)
				end
				recentFile:close()
			end

			-- Step 3: put the items in order. Active items first, then inactive items.
			-- In each group: the recent labels first, then the other labels in the default order.
			-- The session you are in now goes to the end of the active group, because you do not
			-- pick it to go somewhere. Thus Return goes to the session you used before this one.
			local items = {}
			local labelByItemID = {}
			local isAdded = {}
			for _, wantActive in ipairs({ true, false }) do
				for _, labels in ipairs({ recentLabels, defaultLabels }) do
					for _, label in ipairs(labels) do
						local item = itemByLabel[label]
						local isCurrent = label == currentLabel
						if item and not isAdded[label] and not isCurrent and (isActiveLabel[label] == true) == wantActive then
							isAdded[label] = true
							labelByItemID[item.id] = label
							table.insert(items, item)
						end
					end
				end
				if wantActive and currentLabel then
					local currentItem = itemByLabel[currentLabel]
					currentItem.detail = "active, current"
					labelByItemID[currentItem.id] = currentLabel
					table.insert(items, currentItem)
				end
			end

			-- Escape cancels and gives nil.
			local picked = rex.ui.pick({ title = title, items = items })
			if not picked then
				return
			end

			-- Step 4: write the recent file again. Keep 50 labels.
			-- The picked label goes first. The session you leave goes second, also when you
			-- came to it without the picker, so that the next cmd+p has it at the top.
			local pickedLabel = labelByItemID[picked]
			local newRecentLabels = { pickedLabel }
			if currentLabel and currentLabel ~= pickedLabel then
				table.insert(newRecentLabels, currentLabel)
			end
			for _, label in ipairs(recentLabels) do
				if label ~= pickedLabel and label ~= currentLabel and #newRecentLabels < 50 then
					table.insert(newRecentLabels, label)
				end
			end
			rex.exec({ "mkdir", "-p", recentDirectory })
			local writeFile = io.open(recentPath, "w")
			if writeFile then
				writeFile:write(table.concat(newRecentLabels, "\n") .. "\n")
				writeFile:close()
			end

			-- A project id is a directory path. All other ids are session ids.
			if picked:sub(1, 1) ~= "/" then
				rex.client.queue("session.select", { session_id = picked })
				return
			end
			return rex.invoke("project", { dir = picked, agent = agent })
		end,
	})
end

project_picker("pick_project", "Pick Project or Session…", "claude")
project_picker("pick_project_pi", "Pick Project or Session with Pi…", "pi")

rex.bind("cmd+p", "pick_project")
rex.bind("cmd+alt+p", "pick_project_pi")

-- cmd+alt+n and cmd+alt+g: show or hide the nvim or lazygit floating pane of the current tab.
-- The pane is found by its label. If the tab has no such pane, the action makes one
-- in the directory of the focused pane.
local function toggle_floating_pane(name, title, paneLabel, command)
	rex.action({
		name = name,
		title = title,
		run = function(ctx)
			local view = rex.session.view({})
			if not view then
				error(name .. ": cannot read the session", 0)
			end

			local paneLayer = nil
			for _, w in ipairs(view.windows) do
				if w.window_id == view.active_window_id then
					for _, layer in ipairs(w.layers or {}) do
						for _, block in ipairs(layer.blocks or {}) do
							if layer.kind == "floating" and block.label == paneLabel then
								paneLayer = layer
							end
						end
					end
				end
			end

			if paneLayer and paneLayer.state == "minimized" then
				local _, showError = rex.call("session.set_layer_state", {
					session_id = ctx.session_id,
					layer_id = paneLayer.layer_id,
					state = "normal",
					focus = true,
				})
				if showError ~= nil then
					error(showError, 0)
				end
				return
			end

			if paneLayer then
				local _, hideError = rex.call("session.set_layer_state", {
					session_id = ctx.session_id,
					layer_id = paneLayer.layer_id,
					state = "minimized",
				})
				if hideError ~= nil then
					error(hideError, 0)
				end
				return
			end

			-- No such pane in this tab: make one.
			local process = rex.block.call(terminal, "process", { block_id = ctx.block_id })
			if not process then
				error(name .. ": cannot read the process of the focused pane", 0)
			end

			-- The foreground program (for example claude) has the directory the pane works in.
			-- At a shell prompt there can be no foreground entry, so the shell is the fallback.
			local currentDirectory = nil
			if process.foreground and process.foreground.cwd then
				currentDirectory = process.foreground.cwd
			end
			if not currentDirectory then
				for _, ancestor in ipairs(process.ancestors or {}) do
					if ancestor.cwd then
						currentDirectory = ancestor.cwd
						break
					end
				end
			end
			if not currentDirectory then
				error(name .. ": cannot find the directory of the focused pane", 0)
			end

			local _, layerError = rex.call("session.new_layer", {
				session_id = ctx.session_id,
				bounds = floatingPaneBounds,
				focus = true,
				layout = rex.layout.block({
					flavor = "com.superlogical.terminal.shell",
					label = paneLabel,
					options = { cwd = currentDirectory, initial_input = command .. "\n" },
				}),
			})
			if layerError ~= nil then
				error(layerError, 0)
			end
		end,
	})
end

toggle_floating_pane("toggle_nvim", "Show or Hide Nvim", "nvim", "nvim .")
toggle_floating_pane("toggle_lazygit", "Show or Hide Lazygit", "lazygit", "lazygit")

rex.bind("cmd+alt+n", "toggle_nvim")
rex.bind("cmd+alt+g", "toggle_lazygit")

-- alt+q: close the session after a confirm question in the command palette.
-- This is an action, not a key handler, because only an action can ask a question with rex.ui.pick.
rex.action({
	name = "close_session",
	title = "Close Session…",
	run = function(ctx)
		local label = "this session"
		local list = rex.call("session.list")
		for _, s in ipairs(list and list.sessions or {}) do
			if s.session_id == ctx.session_id then
				label = s.label
			end
		end
		-- Return selects the first item. Escape cancels and gives nil.
		local answer = rex.ui.pick({
			title = "Close session " .. label .. "?",
			items = {
				{ id = "close", title = "Close session" },
				{ id = "cancel", title = "Cancel" },
			},
		})
		if answer ~= "close" then
			return
		end
		rex.call("session.destroy", { session_id = ctx.session_id })
	end,
})

rex.bind("alt+q", "close_session")
-- Cycle keys: ctrl acts on tabs in the session, alt acts on sessions.
-- The session names are only in the sidebar. Thus the alt keys go to the session and open the sidebar.
-- You close the sidebar yourself.
-- The app has only a toggle action for the sidebar, so the action first reads from the app
-- preferences if the sidebar is collapsed. Without this check a second key press closes it again.
local function open_sidebar_if_collapsed()
	local collapsed = rex.exec({ "defaults", "read", "com.superlogical.rex", "Workspace.sidebarCollapsed" })
	if collapsed and collapsed.ok and collapsed.stdout:match("1") then
		rex.client.queue("client.sidebar.toggle")
	end
end

rex.action({
	name = "session_next_with_names",
	title = "Next Session, Open Sidebar",
	run = function()
		rex.client.queue("session.next")
		open_sidebar_if_collapsed()
	end,
})

rex.action({
	name = "session_previous_with_names",
	title = "Previous Session, Open Sidebar",
	run = function()
		rex.client.queue("session.previous")
		open_sidebar_if_collapsed()
	end,
})

rex.bind("alt+tab", "session_next_with_names")
rex.bind("alt+shift+tab", "session_previous_with_names")
rex.bind("alt+[", "session_previous_with_names")
rex.bind("alt+]", "session_next_with_names")

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

-- ctrl+1..9: go to tab N of the current session. cmd+1..9 counts tabs of all sessions.
for tabNumber = 1, 9 do
	local name = "session_tab_" .. tabNumber
	rex.action({
		name = name,
		title = "Go to Tab " .. tabNumber .. " in Session",
		run = function(ctx)
			local view = rex.session.view({})
			if not view or not view.windows[tabNumber] then
				return
			end
			rex.client.queue("session.select", {
				session_id = ctx.session_id,
				window_id = view.windows[tabNumber].window_id,
			})
		end,
	})
	rex.bind("ctrl+" .. tabNumber, name)
end

-- cmd+j: show a letter in front of every tab name in all sessions, then press the letter to go to that tab.
-- Any other key cancels. A small floating terminal reads the key, because a Rex mode would show a hint popup.
-- The letters are written into the tab labels as "[a] name", and removed again before the jump.
-- The labels are the only state, so a config reload in between does not leave letters behind.
local jumpHints = "asdfghjklqwertyuiopzxcvbnm"
-- A tab keeps its letter while it is open, so the letters can be learned. Kept in memory until the config reloads.
local jumpHintByWindow = {}

-- Calls visit(session_id, window, title) for every tab of every session, in sidebar order.
local function each_tab(visit)
	local list = rex.call("session.list")
	for _, s in ipairs(list and list.sessions or {}) do
		-- Lua can only read or change a session it is attached to.
		rex.call("session.attach", { session_id = s.session_id })
		local view = rex.session.view({ session_id = s.session_id })
		for _, w in ipairs(view and view.windows or {}) do
			local title = rex.block.call(terminal, "title", { session_id = s.session_id, block_id = w.focused_block_id })
			visit(s.session_id, w, title and title.title or "")
		end
	end
end

local function remove_jump_hints()
	each_tab(function(session_id, w, title)
		local name = w.label
		while name:match("^%[%a%] ") do
			name = name:sub(5)
		end
		if name == w.label then
			return
		end
		-- A tab without its own name showed the terminal title. An empty label gives it the default name back.
		if name == title then
			name = ""
		end
		rex.call("session.set_window_label", { session_id = session_id, window_id = w.window_id, label = name })
	end)
end

rex.action({
	name = "jump_start",
	title = "Jump to Tab…",
	run = function(ctx)
		remove_jump_hints()
		local openTabs = {}
		each_tab(function(session_id, w, title)
			table.insert(openTabs, { session_id = session_id, window = w, title = title })
		end)

		-- Free the letters of closed tabs, then give each new tab the first free letter.
		local isOpen = {}
		for _, tab in ipairs(openTabs) do
			isOpen[tab.window.window_id] = true
		end
		local isLetterUsed = {}
		for windowID, hint in pairs(jumpHintByWindow) do
			if isOpen[windowID] then
				isLetterUsed[hint] = true
			else
				jumpHintByWindow[windowID] = nil
			end
		end
		for _, tab in ipairs(openTabs) do
			if not jumpHintByWindow[tab.window.window_id] then
				for index = 1, #jumpHints do
					local hint = jumpHints:sub(index, index)
					if not isLetterUsed[hint] then
						jumpHintByWindow[tab.window.window_id] = hint
						isLetterUsed[hint] = true
						break
					end
				end
			end
		end

		for _, tab in ipairs(openTabs) do
			-- Past 26 tabs, a tab has no letter.
			local hint = jumpHintByWindow[tab.window.window_id]
			if hint then
				local name = tab.window.label
				if tab.window.label == "Window " .. tab.window.window_id:sub(-8) and tab.title ~= "" then
					name = tab.title
				end
				rex.call("session.set_window_label", {
					session_id = tab.session_id,
					window_id = tab.window.window_id,
					label = "[" .. hint .. "] " .. name,
				})
			end
		end
		local _, err = rex.call("session.new_layer", {
			session_id = ctx.session_id,
			bounds = { 0.3, 0.4, 0.4, 0.1 },
			focus = true,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				options = { command = { os.getenv("HOME") .. "/.config/rex/picker", "jump", ctx.client_id } },
			}),
		})
		if err ~= nil then
			remove_jump_hints()
			error(err, 0)
		end
	end,
})

rex.action({
	name = "jump_to",
	title = "Jump to Tab with Letter",
	args = { hint = "string" },
	run = function(ctx, args)
		local target = nil
		each_tab(function(session_id, w)
			if args.hint ~= "" and w.label:sub(1, 4) == "[" .. args.hint .. "] " then
				target = { session_id = session_id, window_id = w.window_id }
			end
		end)
		remove_jump_hints()
		if not target then
			return
		end
		rex.client.queue("session.select", target)
	end,
})

rex.bind("cmd+j", "jump_start")

-- cmd+k: open a new floating pane, used as a quick terminal.
rex.bind("cmd+k", "pane.new_floating")

local shells = { zsh = true, ["-zsh"] = true, bash = true, sh = true, fish = true }

-- cmd+w: close the pane, but ask first when a program other than the shell runs in it.
-- The nvim and lazygit floating panes are minimized instead, so the program keeps its state.
rex.action({
	name = "close_pane",
	title = "Close Pane, Ask if a Program Runs",
	run = function(ctx)
		local nvimOrLazygitLayer = nil
		local view = rex.session.view({})
		for _, w in ipairs(view and view.windows or {}) do
			for _, layer in ipairs(w.layers or {}) do
				for _, block in ipairs(layer.blocks or {}) do
					if block.block_id == ctx.block_id and layer.kind == "floating" then
						for _, floatingPane in ipairs(floatingPanes) do
							if block.label == floatingPane.label then
								nvimOrLazygitLayer = layer
							end
						end
					end
				end
			end
		end

		if nvimOrLazygitLayer then
			local _, hideError = rex.call("session.set_layer_state", {
				session_id = ctx.session_id,
				layer_id = nvimOrLazygitLayer.layer_id,
				state = "minimized",
			})
			if hideError ~= nil then
				error(hideError, 0)
			end
			return
		end

		local p = rex.block.call(terminal, "process", { block_id = ctx.block_id })
		local fg = p and p.foreground
		if fg and not shells[fg.argv0 or fg.name] then
			local answer = rex.ui.pick({
				title = "Close the pane running " .. (fg.argv0 or fg.name) .. "?",
				items = {
					{ id = "close", title = "Close pane" },
					{ id = "cancel", title = "Cancel" },
				},
			})
			if answer ~= "close" then
				return
			end
		end
		rex.call("block.close", { session_id = ctx.session_id, block_id = ctx.block_id })
	end,
})

rex.bind("cmd+w", "close_pane")

-- Rex keeps interface settings in the app preferences, not in this file.
-- This action sets them, so a new machine gets the same look. Run it one time with: rex do apply_look
rex.action({
	name = "apply_look",
	title = "Apply Look from Config",
	run = function()
		local interface = "client.setting.interface."
		rex.client.queue(interface .. "appearance.style", { value = "glass" })
		rex.client.queue(interface .. "appearance.glass", { value = true })
		rex.client.queue(interface .. "active_panes.fade", { value = "both" })
		rex.client.queue(interface .. "active_panes.active_border", { value = true })
		rex.client.queue(interface .. "active_panes.active_border_color", { value = "text" })
		-- Opacity is a percentage, from 10 to 100.
		rex.client.queue(interface .. "active_panes.active_border_opacity", { value = 50 })
		rex.client.queue(interface .. "pane_padding.horizontal", { value = 12 })
		rex.client.queue(interface .. "pane_padding.vertical", { value = 8 })
	end,
})
