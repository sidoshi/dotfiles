-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = ""

-- Pre-set background to prevent OSC 11 race condition on nvim 0.11 + Ghostty
-- Without this, the terminal's OSC 11 response can leak as keyboard input and crash nvim
vim.o.background = "dark"

-- Disable AI code completion suggestions
-- so that they don't conflict with the ghost text suggestions from copilot
vim.g.ai_cmp = false
-- Force LazyVim to look for .git first, or just follow the terminal CWD
vim.g.root_spec = { ".git", "cwd" }

vim.filetype.add({
  filename = { [".env"] = "dotenv" },
  pattern = { ["%.env%..*"] = "dotenv" },
})

-- Make window separators easier to spot. Heavy box-drawing chars + a brighter
-- color that matches ghostty's split-divider-color so splits look unified.
vim.opt.fillchars:append({
  vert = "┃",
  horiz = "━",
  horizup = "┻",
  horizdown = "┳",
  vertleft = "┫",
  vertright = "┣",
  verthoriz = "╋",
})
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ccbbaa", bold = true })
  end,
})
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ccbbaa", bold = true })
