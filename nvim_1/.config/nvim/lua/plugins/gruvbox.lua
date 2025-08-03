return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000, -- load before other plugins
    config = function()
      require("gruvbox").setup({
        contrast = "hard", -- optional: "soft", "hard", or empty
        transparent_mode = true, -- enable transparency
        dim_inactive = false,
      })
      vim.cmd.colorscheme("gruvbox")
      -- Make statusline and other UI elements transparent
      -- vim.api.nvim_set_hl(0, "StatusLine", { bg = "none", fg = "#ebdbb2" })
      -- vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none", fg = "#a89984" })
      -- vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none", fg = "#504945" })
    end,
  },
}
