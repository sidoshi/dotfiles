return {

  {
    "EdenEast/nightfox.nvim",
    opts = {
      groups = {
        all = {
          Visual = { bg = "#3e4a5b" },
        },
      },
    },
  },
  {
    "vague-theme/vague.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other plugins
    config = function()
      require("vague").setup({
        -- optional configuration here
      })
    end,
  },
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "carbonfox",
    },
  },
}
