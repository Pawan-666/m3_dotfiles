return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  event = "VeryLazy",
  keys = {
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
    { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
    { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
    { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
  },
  opts = {
    options = {
      close_command = "bdelete! %d",
      right_mouse_command = "bdelete! %d", 
      diagnostics = "nvim_lsp",
      always_show_bufferline = false,
      diagnostics_indicator = function(_, _, diag)
        local ret = (diag.error and " " .. diag.error .. " " or "")
          .. (diag.warning and " " .. diag.warning or "")
        return vim.trim(ret)
      end,
      offsets = {
        {
          filetype = "neo-tree",
          text = "Neo-tree",
          highlight = "Directory",
          text_align = "left",
        },
      },
      ---@param opts bufferline.IconFetcherOpts
      get_element_icon = function(opts)
        return nil -- Use default icons
      end,
      -- Custom styling for your transparent theme
      style_preset = "default",
      separator_style = "thin",
      indicator = {
        icon = "▎",
        style = "icon",
      },
      buffer_close_icon = "󰅖",
      modified_icon = "●",
      close_icon = "",
      left_trunc_marker = "",
      right_trunc_marker = "",
      max_name_length = 30,
      max_prefix_length = 30,
      truncate_names = true,
      tab_size = 21,
      color_icons = true,
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = true,
      show_tab_indicators = true,
      show_duplicate_prefix = true,
      persist_buffer_sort = true,
      move_wraps_at_ends = false,
      enforce_regular_tabs = false,
      auto_toggle_bufferline = true,
      hover = {
        enabled = true,
        delay = 200,
        reveal = {'close'}
      },
      sort_by = "insert_after_current",
      
      -- Custom highlights to match your Gruvbox transparent theme
      highlights = {
        background = {
          bg = "none"
        },
        buffer_selected = {
          bold = true,
          italic = false,
        },
        close_button = {
          bg = "none"
        },
        close_button_visible = {
          bg = "none"
        },
        close_button_selected = {
          bg = "none"
        },
        fill = {
          bg = "none"
        },
        separator = {
          bg = "none"
        },
        separator_visible = {
          bg = "none"
        },
        separator_selected = {
          bg = "none"
        },
        tab_separator = {
          bg = "none"
        },
        tab_separator_selected = {
          bg = "none"
        },
      },
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)
    -- Fix bufferline when restoring a session
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function()
          pcall(nvim_bufferline)
        end)
      end,
    })
  end,
}