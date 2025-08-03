return {
  "rcarriga/nvim-notify",
  keys = {
    {
      "<leader>un",
      function()
        require("notify").dismiss({ silent = true, pending = true })
      end,
      desc = "Dismiss All Notifications",
    },
  },
  opts = {
    stages = "static",
    timeout = 3000,
    max_height = function()
      return math.floor(vim.o.lines * 0.75)
    end,
    max_width = function()
      return math.floor(vim.o.columns * 0.75)
    end,
    on_open = function(win)
      vim.api.nvim_win_set_config(win, { zindex = 100 })
    end,
    -- Transparent background to match your gruvbox theme
    background_colour = "#000000",
    render = "compact",
    top_down = false,
  },
  init = function()
    -- Set notify as default notification handler
    vim.defer_fn(function()
      vim.notify = require("notify")
    end, 50)
  end,
}