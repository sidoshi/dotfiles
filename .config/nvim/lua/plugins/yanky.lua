vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })

return {
  "gbprod/yanky.nvim",
  keys = {
    { "<leader>p", false },
    { "<leader>fP", "<cmd>YankyRingHistory<cr>", desc = "Paste (Yank History)" },
  },
}
