return {
  -- Collection of various small independent plugins/modules
  {
    "echasnovski/mini.nvim",
    config = function()
      -- Better Around/Inside textobjects
      require("mini.ai").setup({ n_lines = 500 })
      
      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      require("mini.surround").setup()
      
      -- Simple and easy statusline
      -- NOTE: We're using lualine instead, so we disable this
      -- require("mini.statusline").setup({ use_icons = vim.g.have_nerd_font })
      
      -- Simple autopairs
      require("mini.pairs").setup()
      
      -- Fast and feature-rich fuzzy finder
      -- NOTE: We're using telescope instead, so we disable this
      -- require("mini.pick").setup()
      
      -- Collection of various small independent plugins/modules
      require("mini.comment").setup()
      
      -- Move any selection in any direction
      require("mini.move").setup({
        mappings = {
          -- Move visual selection in Visual mode
          left = '<M-h>',
          right = '<M-l>',
          down = '<M-j>',
          up = '<M-k>',
          
          -- Move current line in Normal mode
          line_left = '<M-h>',
          line_right = '<M-l>',
          line_down = '<M-j>',
          line_up = '<M-k>',
        },
      })
      
      -- Highlight word under cursor
      require("mini.cursorword").setup()
      
      -- Extend and create a/i textobjects
      require("mini.ai").setup({
        n_lines = 500,
        custom_textobjects = {
          o = require("mini.ai").gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          d = { "%f[%d]%d+" }, -- digits
          e = { -- Word with case
            {
              "%u[%l%d]+%f[^%l%d]",
              "%f[%S][%l%d]+%f[^%l%d]",
              "%f[%P][%l%d]+%f[^%l%d]",
              "^[%l%d]+%f[^%l%d]",
            },
            "^().*()$",
          },
          g = function() -- Whole buffer, similar to `gg` and 'G' motion
            local from = { line = 1, col = 1 }
            local to = {
              line = vim.fn.line("$"),
              col = math.max(vim.fn.getline("$"):len(), 1)
            }
            return { from = from, to = to }
          end,
        },
      })
      
      -- File explorer
      require("mini.files").setup({
        content = {
          filter = nil,
          prefix = nil,
          sort = nil,
        },
        mappings = {
          close       = 'q',
          go_in       = 'l',
          go_in_plus  = 'L',
          go_out      = 'h',
          go_out_plus = 'H',
          mark_goto   = "'",
          mark_set    = 'm',
          reset       = '<BS>',
          reveal_cwd  = '@',
          show_help   = 'g?',
          synchronize = '=',
          trim_left   = '<',
          trim_right  = '>',
        },
        options = {
          permanent_delete = true,
          use_as_default_explorer = false,
        },
        windows = {
          max_number = math.huge,
          preview = false,
          width_focus = 25,
          width_nofocus = 15,
          width_preview = 25,
        },
      })
      
      -- Animate common Neovim actions
      require("mini.animate").setup({
        cursor = {
          enable = false,
        },
        scroll = {
          enable = false,
        },
        resize = {
          enable = false,
        },
        open = {
          enable = false,
        },
        close = {
          enable = false,
        },
      })
      
      -- Visualize and work with indent scope
      require("mini.indentscope").setup({
        symbol = "│",
        options = { try_as_border = true },
      })
      
      -- Split/join arguments
      require("mini.splitjoin").setup()
      
      -- Trailing whitespace
      require("mini.trailspace").setup()
      
      -- Extend f, F, t, T
      require("mini.jump").setup()
      
      -- Work with variants of word under cursor
      require("mini.extra").setup()
    end,
  },
  
  -- Add mappings for mini.files
  {
    "echasnovski/mini.files",
    opts = {},
    keys = {
      {
        "<leader>fm",
        function()
          require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = "Open mini.files (Directory of Current File)",
      },
      {
        "<leader>fM",
        function()
          require("mini.files").open(vim.uv.cwd(), true)
        end,
        desc = "Open mini.files (cwd)",
      },
    },
    config = function(_, opts)
      require("mini.files").setup(opts)
      
      local show_dotfiles = true
      local filter_show = function(fs_entry)
        return true
      end
      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end
      
      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        require("mini.files").refresh({ content = { filter = new_filter } })
      end
      
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id })
        end,
      })
      
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesActionRename",
        callback = function(event)
          -- Handle LSP file rename if needed
          -- LazyVim.lsp.on_rename(event.data.from, event.data.to)
        end,
      })
    end,
  },
}