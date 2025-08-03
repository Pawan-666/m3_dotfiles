return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {},
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>qS", function() require("persistence").select() end, desc = "Select Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
  },
  config = function(_, opts)
    require("persistence").setup(opts)
    
    -- Enhanced session management
    require("persistence").setup({
      dir = vim.fn.stdpath("state") .. "/sessions/",
      need = 1,
      branch = true, -- use git branch in session name
      options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" },
      pre_save = nil,
      save_empty = false,
    })
  end,
}