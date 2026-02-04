return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>fy",
      function()
        require("yazi").yazi()
      end,
      desc = "Open yazi at the current file",
    },
    {
      "<leader>fY",
      function()
        require("yazi").yazi(nil, vim.fn.getcwd())
      end,
      desc = "Open yazi in nvim's working directory",
    },
  },
  opts = {
    -- if you want to replace netrw entirely
    open_for_directories = false,
    keymaps = {
      show_help = "<f1>",
    },
  },
}
