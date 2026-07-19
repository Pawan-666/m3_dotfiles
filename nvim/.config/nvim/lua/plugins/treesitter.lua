return {
  -- Main treesitter — let LazyVim v16's config handle the new API.
  -- We only override opts here (ensure_installed is merged via opts_extend).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
        -- Additional languages for blog content and development
        "css",
        "scss",
        "go",
        "rust",
        "dockerfile",
        "gitignore",
        "sql",
      },
    },
  },

  -- Textobjects: LazyVim handles move keymaps; add select + swap here.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    config = function(_, opts)
      local TS = require("nvim-treesitter-textobjects")
      if not TS.setup then
        return
      end
      TS.setup(opts)

      local select_maps = {
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["ii"] = "@conditional.inner",
        ["ai"] = "@conditional.outer",
        ["il"] = "@loop.inner",
        ["al"] = "@loop.outer",
        ["at"] = "@comment.outer",
      }

      local function attach(buf)
        local ft = vim.bo[buf].filetype
        if not pcall(require("lazyvim.util").treesitter.have, ft, "textobjects") then
          return
        end
        for key, query in pairs(select_maps) do
          vim.keymap.set({ "x", "o" }, key, function()
            require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
          end, { buffer = buf, silent = true })
        end
        vim.keymap.set("n", "<leader>a", function()
          require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner", "textobjects")
        end, { buffer = buf, silent = true, desc = "Swap next parameter" })
        vim.keymap.set("n", "<leader>A", function()
          require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner", "textobjects")
        end, { buffer = buf, silent = true, desc = "Swap prev parameter" })
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_textobjects_keymaps", { clear = true }),
        callback = function(ev)
          attach(ev.buf)
        end,
      })
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        attach(buf)
      end
    end,
  },

  -- Treesitter context
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      enable = true,
      max_lines = 0,
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20,
      trim_scope = "outer",
      mode = "cursor",
      zindex = 20,
    },
  },
}
