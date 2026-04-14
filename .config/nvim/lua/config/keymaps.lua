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

-- CodeDiff
vim.keymap.set("n", "<leader>gd", "<cmd>CodeDiff<cr>",                   { desc = "Diff working tree" })
vim.keymap.set("n", "<leader>gL", "<cmd>CodeDiff history<cr>",           { desc = "Commit history" })
vim.keymap.set("n", "<leader>gH", "<cmd>CodeDiff history HEAD~20 %<cr>", { desc = "File history" })
vim.keymap.set("n", "<leader>gm", "<cmd>CodeDiff main...<cr>",           { desc = "Diff vs main (PR)" })
vim.keymap.set("n", "<leader>g1", "<cmd>CodeDiff HEAD~1<cr>",            { desc = "Diff HEAD~1" })
vim.keymap.set("n", "<leader>g2", "<cmd>CodeDiff HEAD~2<cr>",            { desc = "Diff HEAD~2" })

-- LSP call hierarchy
vim.keymap.set("n", "<leader>cci", vim.lsp.buf.incoming_calls, { desc = "Incoming Calls" })
vim.keymap.set("n", "<leader>cco", vim.lsp.buf.outgoing_calls, { desc = "Outgoing Calls" })
