return {
  "folke/snacks.nvim",
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
        explorer = {
          hidden = true,
          jump = { close = true },
        },
      },
    },
    explorer = { enabled = true },
  },
}
