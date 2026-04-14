return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    opts = {
      keymaps = {
        view = {
          toggle_layout = "t",
        },
      },
    },
    config = function(_, opts)
      require("codediff").setup(opts)

      -- <Tab> in the codediff explorer jumps to the diff pane (plugin has no focus_diff action)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "codediff-explorer",
        callback = function(ev)
          vim.keymap.set("n", "<Tab>", "<C-w>l", { buffer = ev.buf, desc = "Focus diff pane" })
        end,
      })
    end,
  },
}
