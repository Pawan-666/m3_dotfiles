-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local map = vim.keymap.set
-- local wk = require("which-key")

-- Basic Commands
map("n", "<C-s>", ":w<CR>", { desc = "Save file" })
map("n", "<Leader>s", ":w<CR>", { desc = "Save file" })
map("n", "<Leader>q", ":qa!<CR>", { desc = "Quit all" })
map("n", "<Leader>d", ":bd<CR>", { desc = "Close buffer" })
map("n", "<Leader>p", "ggVGp", { desc = "Paste over entire file" })
map("n", "<Leader><Leader>", "<C-^>", { desc = "Switch to previous file" })
map("n", "<leader>P", ":lua require('img-clip').paste_image()<CR>", { desc = "Paste Image" })

-- Toggling options
map("n", "<Leader>S", ":setlocal spell! spelllang=en_us<CR>", { desc = "Toggle Spell" })
map("n", "<Leader>C", ":set cuc!<CR>", { desc = "Toggle cursor column" })
map("n", "<Leader>n", ":set nu! rnu!<CR>", { desc = "Toggle line numbers" })
map("n", "<Leader>W", ":set wrap!<CR>", { desc = "Toggle line wrap" })
map("n", "<Leader>L", ":LspStop<CR>", { desc = "LSP Stop" })
-- map("n", "<Leader>a", ":ASToggle<CR>", { desc = "Toggle AutoSave" })

-- -- Markdown and clipboard-image.nvim
-- map("n", "<Leader>M", ":MarkdownPreviewToggle<CR>", { desc = "Toggle Markdown Preview" })
-- map("n", "'p", ":PasteImg<CR>o", { desc = "Paste image" })
-- map("i", "'P", "<esc>:PasteImg<CR>o", { desc = "Paste image (insert)" })

-- -- Markdown editing shortcuts
-- map("i", "'1", "# <esc>a")
-- map("i", "'2", "## <esc>a")
-- map("i", "'3", "### <esc>a")
-- map("i", "'4", "#### <esc>a")
-- map("i", "'5", "##### <esc>a")
-- map("i", "'B", "____<esc>hi")
-- map("i", "'T", '+++<CR>title = "Blog_title"<CR>date = 2023-02-01<CR>+++<CR><CR>')
-- map("i", "'I", "**<esc>i")
-- map("i", "'M", "``<esc>i")
-- map("i", "'R", "---<CR>")
-- map("i", "'L", "[]()<esc>Ba")
-- map("i", "'C", "``````<esc>2hi<CR><CR><esc>hi")  -- bash
-- map("i", "'b", "    ")

-- Movement (soft-wrapped lines)
map("n", "j", "gj", { desc = "Down (visual)" })
map("n", "k", "gk", { desc = "Up (visual)" })

-- Buffer Navigation
map("n", "<C-j>", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
-- map("n", "<C-k>", ":BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
map("n", "gt", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "gT", ":BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
map("n", "<C-k>", "gT", { desc = "Buffer UP " })

-- File Explorer or Picker
-- map("n", "<C-t>", ":NnnPicker %:p:h<CR>", { desc = "Nnn Picker" })

-- Insert mode shortcuts
map("i", "<C-e>", "<esc>$i<right>")
map("i", "<C-a>", "<esc>0i")
map("i", "<C-f>", "<Right>")
map("i", "<C-b>", "<Left>")
map("i", "jj", "<Esc>")
map("i", "kk", "<Esc>")

-- Command mode save as sudo
vim.cmd([[cnoreabbrev w!! w !sudo tee > /dev/null %]])

-- Map <Leader>/ to 'gcc' in normal mode
vim.api.nvim_set_keymap("n", "<Leader>/", "gcc", { noremap = false, silent = true })

-- Map <Leader>/ to 'gc' in visual mode
vim.api.nvim_set_keymap("v", "<Leader>/", "gc", { noremap = false, silent = true })

-- Add inside your which-key config (usually ~/.config/nvim/lua/plugins/which-key.lua or similar)

-- vim.keymap.set("n", "<leader>ul", function()
--   vim.cmd("LspStop")
--   vim.defer_fn(function()
--     vim.cmd("LspStart")
--   end, 100) -- wait 100ms before restarting
-- end, { desc = "Force restart LSP" })

map("n", "L", ":LspStart<CR>", { desc = "lsp start" })

-- Ensure undo/redo work properly (explicit mappings to override any conflicts)
map("n", "u", function()
  if vim.fn.undotree().seq_cur > 0 then
    vim.cmd("undo")
  else
    vim.notify("Already at oldest change", vim.log.levels.WARN)
  end
end, { desc = "Undo" })

map("n", "<C-r>", function()
  local ut = vim.fn.undotree()
  if ut.seq_cur < ut.seq_last then
    vim.cmd("redo")
  else
    vim.notify("Already at newest change", vim.log.levels.WARN)
  end
end, { desc = "Redo" })
