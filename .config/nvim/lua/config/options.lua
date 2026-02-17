-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = ""

-- Disable AI code completion suggestions
-- so that they don't conflict with the ghost text suggestions from copilot
vim.g.ai_cmp = false
-- Force LazyVim to look for .git first, or just follow the terminal CWD
vim.g.root_spec = { ".git", "cwd" }

vim.filetype.add({
  filename = { [".env"] = "dotenv" },
  pattern = { ["%.env%..*"] = "dotenv" },
})
