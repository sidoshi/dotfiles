return {
  {
    "supermaven-inc/supermaven-nvim",
    cond = function()
      local cwd = vim.fn.getcwd()
      return not vim.startswith(cwd, vim.fn.expand("~/forto"))
    end,
  },
}
