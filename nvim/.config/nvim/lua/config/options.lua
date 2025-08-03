-- Enhanced options for blog writing and development workflow
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- ════════════════════════════════════════════════════════════════
-- 📝 BLOG WRITING ENHANCEMENTS
-- ════════════════════════════════════════════════════════════════

-- Enhanced markdown editing
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  callback = function()
    vim.opt_local.conceallevel = 0      -- disable conceal in markdown
    vim.opt_local.wrap = true           -- wrap long lines
    vim.opt_local.linebreak = true      -- break at word boundaries
    vim.opt_local.spell = true          -- enable spell check
    vim.opt_local.spelllang = "en_us"   -- set spell language
    vim.opt_local.textwidth = 80        -- optimal reading width
    vim.opt_local.colorcolumn = "80"    -- visual guide
  end,
})

-- ════════════════════════════════════════════════════════════════
-- ⚡ PERFORMANCE IMPROVEMENTS
-- ════════════════════════════════════════════════════════════════

-- Faster startup and responsiveness
vim.opt.updatetime = 250              -- faster completion popup (default: 4000)
vim.opt.timeoutlen = 300              -- faster which-key popup (default: 1000)
vim.opt.redrawtime = 10000            -- allow more time for loading
vim.opt.scrolloff = 8                 -- keep 8 lines visible when scrolling
vim.opt.sidescrolloff = 8             -- horizontal scroll padding

-- ════════════════════════════════════════════════════════════════
-- 🎨 VISUAL IMPROVEMENTS
-- ════════════════════════════════════════════════════════════════

-- Enhanced UI
vim.opt.termguicolors = true          -- true color support
vim.opt.signcolumn = "yes"            -- always show sign column
vim.opt.number = true                 -- show line numbers
vim.opt.relativenumber = true         -- relative line numbers
vim.opt.cursorline = true             -- highlight current line
vim.opt.splitbelow = true             -- horizontal splits go below
vim.opt.splitright = true             -- vertical splits go right

-- ════════════════════════════════════════════════════════════════
-- 🔍 SEARCH IMPROVEMENTS  
-- ════════════════════════════════════════════════════════════════

vim.opt.ignorecase = true             -- ignore case in search
vim.opt.smartcase = true              -- case sensitive if uppercase used
vim.opt.hlsearch = false              -- no highlight search (your preference)
vim.opt.incsearch = true              -- show match as you type

-- ════════════════════════════════════════════════════════════════
-- 💾 FILE HANDLING
-- ════════════════════════════════════════════════════════════════

-- Better backup handling (you have auto-save plugin)
vim.opt.backup = false                -- no backup files
vim.opt.writebackup = false           -- no backup before writing
vim.opt.swapfile = false              -- no swap files
vim.opt.undofile = true               -- persistent undo

-- ════════════════════════════════════════════════════════════════
-- ⌨️  EDITING BEHAVIOR
-- ════════════════════════════════════════════════════════════════

-- Smart indenting
vim.opt.autoindent = true             -- maintain indent
vim.opt.smartindent = true            -- smart indent for code
vim.opt.expandtab = true              -- use spaces instead of tabs
vim.opt.tabstop = 2                   -- tab width
vim.opt.shiftwidth = 2                -- indent width
vim.opt.softtabstop = 2               -- soft tab width

-- Better completion
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.pumheight = 10                -- limit popup menu height

-- ════════════════════════════════════════════════════════════════
-- 🔧 SYSTEM INTEGRATION
-- ════════════════════════════════════════════════════════════════

vim.opt.clipboard = "unnamedplus"     -- use system clipboard
vim.opt.mouse = "a"                   -- enable mouse in all modes

-- Disable LazyVim integrations to prevent conflicts
vim.g.trouble_lualine = false
