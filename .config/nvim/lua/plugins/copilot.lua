return {
  {
    "zbirenbaum/copilot.lua",
    opts = function()
      -- Override ai_accept so that Tab (via blink.cmp) accepts one word at a time
      LazyVim.cmp.actions.ai_accept = function()
        if require("copilot.suggestion").is_visible() then
          LazyVim.create_undo()
          require("copilot.suggestion").accept_word()
          return true
        end
      end
    end,
    keys = {
      {
        "<S-Tab>",
        function()
          if require("copilot.suggestion").is_visible() then
            require("copilot.suggestion").accept()
          end
        end,
        mode = "i",
        desc = "Accept full Copilot suggestion",
      },
    },
  },
}
