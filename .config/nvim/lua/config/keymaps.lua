-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.keymap.del("n", "<leader>|")
vim.keymap.del("n", "<leader>-")

-- Add window maximize toggle using Ctrl+w z (similar to tmux prefix+z)
vim.keymap.set("n", "<C-w>z", "<C-w>|<C-w>_", { desc = "Maximize current window" })
-- Add a second mapping to restore windows to equal size
vim.keymap.set("n", "<C-w>Z", "<C-w>=", { desc = "Restore windows to equal size" })

-- Add a keymap to delete a buffer
vim.keymap.set("n", "Q", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
-- Add a keymap to reopen the last buffer
vim.keymap.set("n", "T", "<cmd>e #<cr>", { desc = "Reopen last buffer" })
