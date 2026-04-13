return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>e",
      function()
        local explorer = Snacks.picker.get({ source = "explorer" })[1]
        if not explorer then
          Snacks.explorer()
        elseif explorer:is_focused() then
          explorer:close()
        else
          explorer:focus()
        end
      end,
      desc = "Explorer",
    },
  },
  opts = {
    -- Minimalist dashboard configuration
    dashboard = {
      enabled = true,
      width = 60,
      row = nil, -- center vertically
      col = nil, -- center horizontally
      pane_gap = 4,
      sections = {
        -- Simple header (optional - remove if too much)
        {
          text = {
            { "neovim", hl = "SnacksDashboardHeader" },
          },
          gap = 1,
          align = "center",
        },
        -- Essential keymaps only
        {
          section = "keys",
          gap = 1,
          padding = 1,
        },
        -- Minimal startup info
        { section = "startup" },
      },
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "r", desc = "Recent", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
    picker = {
      sources = {
        files = {
          hidden = true,
        },
        explorer = {
          hidden = true,
        },
      },
    },
    explorer = { enabled = true, replace_netrw = false },
  },
}
