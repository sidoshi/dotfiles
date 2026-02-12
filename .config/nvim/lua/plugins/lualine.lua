return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local function jj_branch()
      if vim.fn.executable("jj") ~= 1 then
        return ""
      end

      local cmd =
        [[jj log -r @ --no-graph --ignore-working-copy --color never --limit 1 -T 'change_id.shortest(4) ++ " " ++ bookmarks' 2>/dev/null]]

      local handle = io.popen(cmd)
      if not handle then
        return ""
      end
      local result = handle:read("*a")
      handle:close()

      local info = result:gsub("^%s+", ""):gsub("%s+$", "")
      return info ~= "" and ("🥋 " .. info) or ""
    end

    table.insert(opts.sections.lualine_b, {
      jj_branch,
      cond = function()
        return vim.fn.isdirectory(".jj") == 1
      end,
      color = { fg = "#ffffff", gui = "bold" },
    })

    opts.sections.lualine_z = {}
  end,
}
