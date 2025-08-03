return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000, -- load before other plugins
    lazy = false,    -- ensure it loads immediately
    config = function()
      require("gruvbox").setup({
        contrast = "hard", -- optional: "soft", "hard", or empty
        transparent_mode = true, -- enable transparency
        dim_inactive = false,
        undercurl = true,
        underline = true,
        bold = true,
        italic = {
          strings = true,
          emphasis = true,
          comments = true,
          operators = false,
          folds = true,
        },
        strikethrough = true,
        invert_selection = false,
        invert_signs = false,
        invert_tabline = false,
        invert_intend_guides = false,
        inverse = true,
        palette_overrides = {},
        overrides = {},
      })
      vim.cmd.colorscheme("gruvbox")
      
      -- Force transparency after colorscheme loads
      vim.schedule(function()
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
      end)
    end,
  },
}
