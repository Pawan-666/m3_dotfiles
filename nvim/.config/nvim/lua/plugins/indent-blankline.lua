return {
  "lukas-reineke/indent-blankline.nvim",
  event = "LazyFile",
  keys = {
    {
      "<leader>ug",
      function()
        local ibl = require("ibl")
        local config = require("ibl.config").get_config(0)
        if config.enabled then
          ibl.setup_buffer(0, { enabled = false })
          vim.notify("Indentation guides disabled", vim.log.levels.INFO)
        else
          ibl.setup_buffer(0, { enabled = true })
          vim.notify("Indentation guides enabled", vim.log.levels.INFO)
        end
      end,
      desc = "Toggle Indentation Guides",
    },
  },
  opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { 
        show_start = false, 
        show_end = false,
        include = {
          node_type = {
            ["*"] = {
              "class",
              "return_statement",
              "function",
              "method",
              "^if",
              "^while",
              "jsx_element",
              "^for",
              "^object",
              "^table",
              "block",
              "arguments",
              "if_statement",
              "else_clause",
              "jsx_element",
              "jsx_self_closing_element",
              "try_statement",
              "catch_clause",
              "import_statement",
              "operation_type",
            },
          },
        },
      },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    },
  main = "ibl",
}