return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    -- Set up diagnostics
    vim.diagnostic.config({
      underline = true,
      update_in_insert = false,
      virtual_text = {
        spacing = 4,
        source = "if_many",
        prefix = "●",
      },
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "",
          [vim.diagnostic.severity.WARN] = "",
          [vim.diagnostic.severity.HINT] = "",
          [vim.diagnostic.severity.INFO] = "",
        },
      },
    })
    
    -- Set up capabilities for nvim-cmp integration
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    if has_cmp and cmp_nvim_lsp and cmp_nvim_lsp.default_capabilities then
      capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())
    end
    
    -- Common on_attach function
    local on_attach = function(client, bufnr)
      local opts = { noremap = true, silent = true, buffer = bufnr }
      
      -- LSP keymaps
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
      vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "<leader>f", function()
        vim.lsp.buf.format({ async = true })
      end, opts)
      
      -- Enable inlay hints if available
      if client.supports_method("textDocument/inlayHint") and vim.lsp.inlay_hint then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end
      
      -- Highlight symbol under cursor
      if client.supports_method("textDocument/documentHighlight") then
        local highlight_group = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          buffer = bufnr,
          group = highlight_group,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd("CursorMoved", {
          buffer = bufnr,
          group = highlight_group,
          callback = vim.lsp.buf.clear_references,
        })
      end
    end
    
    -- Server configurations
    local servers = {
      -- Lua
      lua_ls = {
        settings = {
          Lua = {
            workspace = {
              checkThirdParty = false,
            },
            completion = {
              callSnippet = "Replace",
            },
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      },
      
      -- Python
      pyright = {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      },
      
      -- JavaScript/TypeScript (tsserver is deprecated, use ts_ls)
      ts_ls = {},
      
      -- JSON
      jsonls = {},
      
      -- YAML
      yamlls = {},
      
      -- Markdown
      marksman = {},
      
      -- Bash
      bashls = {},
      
      -- CSS
      cssls = {},
      
      -- HTML
      html = {},
      
      -- Go
      gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            codelenses = {
              gc_details = false,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            analyses = {
              fieldalignment = true,
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
            semanticTokens = true,
          },
        },
      },
    }
    
    -- Setup servers
    local lspconfig = require("lspconfig")
    
    -- Get mason-lspconfig for automatic server installation
    local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
    if mason_lspconfig_ok then
      mason_lspconfig.setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_installation = true,
      })
      
      mason_lspconfig.setup_handlers({
        function(server_name)
          local server_config = servers[server_name] or {}
          server_config.capabilities = capabilities
          server_config.on_attach = on_attach
          lspconfig[server_name].setup(server_config)
        end,
      })
    else
      -- Fallback: setup servers manually
      for server_name, server_config in pairs(servers) do
        server_config.capabilities = capabilities
        server_config.on_attach = on_attach
        lspconfig[server_name].setup(server_config)
      end
    end
  end,
}