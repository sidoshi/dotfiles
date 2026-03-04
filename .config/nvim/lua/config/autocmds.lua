-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Re-sign .so files after :Lazy operations to prevent macOS code signature crashes
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyInstall",
  callback = function()
    local data_dir = vim.fn.stdpath("data")
    vim.fn.system({ "find", data_dir, "-name", "*.so", "-exec", "codesign", "--force", "--sign", "-", "{}", ";" })
  end,
})

-- The Vague color scheme has a contrast issue with the LSP reference highlights
-- This autocmd fixes that by setting custom highlights for LSP references
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- This sets the background for the word under the cursor and its matches
    -- Adjust 'bg' to something that contrasts with your theme's background
    vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#3e4452", bold = true })
    vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#3e4452", bold = true })
    vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#3e4452", underline = true })
  end,
})

-- This forces spell off specifically for markdown files,
-- overriding the lang.markdown default.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
