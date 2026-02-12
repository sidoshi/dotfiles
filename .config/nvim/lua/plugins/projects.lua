return {
  {
    "ahmedkhalf/project.nvim",
    opts = {
      manual_mode = false,
      detection_methods = { "lsp", "pattern" },
      patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" },
    },
    config = function(_, opts)
      require("project_nvim").setup(opts)
    end,
    keys = {
      {
        "<leader>fp",
        function()
          local history = require("project_nvim.utils.history")
          local projects = history.get_recent_projects()

          -- 1. Items, 2. Options, 3. On_Select callback
          Snacks.picker.select(projects, {
            prompt = "Projects",
          }, function(item)
            if item then
              vim.fn.chdir(item)
              Snacks.picker.files()
            end
          end)
        end,
        desc = "Projects (Snacks)",
      },
    },
  },
}
