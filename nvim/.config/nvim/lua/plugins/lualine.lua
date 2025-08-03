return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      globalstatus = true,
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
    },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diff'},
      lualine_c = {'filename'},
      lualine_x = {'encoding', 'fileformat', 'filetype'},
      lualine_y = {'progress'},
      lualine_z = {'location'}
    },
  },
  config = function(_, opts)
    require("lualine").setup(opts)
    
    -- Force transparent background after setup
    vim.cmd([[
      highlight lualine_a_normal guibg=NONE ctermbg=NONE
      highlight lualine_b_normal guibg=NONE ctermbg=NONE  
      highlight lualine_c_normal guibg=NONE ctermbg=NONE
      highlight lualine_x_normal guibg=NONE ctermbg=NONE
      highlight lualine_y_normal guibg=NONE ctermbg=NONE
      highlight lualine_z_normal guibg=NONE ctermbg=NONE
      highlight lualine_a_insert guibg=NONE ctermbg=NONE
      highlight lualine_b_insert guibg=NONE ctermbg=NONE
      highlight lualine_c_insert guibg=NONE ctermbg=NONE
      highlight lualine_x_insert guibg=NONE ctermbg=NONE
      highlight lualine_y_insert guibg=NONE ctermbg=NONE
      highlight lualine_z_insert guibg=NONE ctermbg=NONE
      highlight lualine_a_visual guibg=NONE ctermbg=NONE
      highlight lualine_b_visual guibg=NONE ctermbg=NONE
      highlight lualine_c_visual guibg=NONE ctermbg=NONE
      highlight lualine_x_visual guibg=NONE ctermbg=NONE
      highlight lualine_y_visual guibg=NONE ctermbg=NONE
      highlight lualine_z_visual guibg=NONE ctermbg=NONE
      highlight lualine_a_command guibg=NONE ctermbg=NONE
      highlight lualine_b_command guibg=NONE ctermbg=NONE
      highlight lualine_c_command guibg=NONE ctermbg=NONE
      highlight lualine_x_command guibg=NONE ctermbg=NONE
      highlight lualine_y_command guibg=NONE ctermbg=NONE
      highlight lualine_z_command guibg=NONE ctermbg=NONE
    ]])
  end,
}