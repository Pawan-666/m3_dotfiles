return {
  "williamboman/mason.nvim",
  cmd = "Mason",
  keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
  build = ":MasonUpdate",
  opts_extend = { "ensure_installed" },
  opts = {
    ensure_installed = {
      -- LSP servers
      "lua-language-server",
      "pyright",
      "typescript-language-server", -- This installs ts_ls
      "json-lsp",
      "yaml-language-server",
      "marksman",
      "bash-language-server",
      "css-lsp",
      "html-lsp",
      "gopls",

      -- Formatters
      "stylua",
      "shfmt",
      "prettier",
      "black",
      "isort",
      "gofumpt",
      "goimports",

      -- Linters
      "shellcheck",
      "flake8",
      "pylint",
      "eslint_d",
      "markdownlint",
      "yamllint",

      -- DAP (Debug Adapter Protocol)
      "debugpy",
      "node-debug2-adapter",
      "delve",
    },
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
      border = "rounded",
      width = 0.8,
      height = 0.9,
      keymaps = {
        toggle_package_expand = "<CR>",
        install_package = "i",
        update_package = "u",
        check_package_version = "c",
        update_all_packages = "U",
        check_outdated_packages = "C",
        uninstall_package = "X",
        cancel_installation = "<C-c>",
        apply_language_filter = "<C-f>",
      },
    },
    max_concurrent_installers = 4,
    github = {
      download_url_template = "https://github.com/%s/releases/download/%s/%s",
    },
    pip = {
      upgrade_pip = false,
      install_args = {},
    },
    log_level = vim.log.levels.INFO,
  },
  config = function(_, opts)
    require("mason").setup(opts)
    local mr = require("mason-registry")
    mr:on("package:install:success", function()
      vim.defer_fn(function()
        require("lazy.core.handler.event").trigger({
          event = "FileType",
          buf = vim.api.nvim_get_current_buf(),
        })
      end, 100)
    end)

    local function ensure_installed()
      for _, tool in ipairs(opts.ensure_installed) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end

    if mr.refresh then
      mr.refresh(ensure_installed)
    else
      ensure_installed()
    end
  end,
}

