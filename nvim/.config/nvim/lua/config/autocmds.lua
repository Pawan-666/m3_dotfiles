-- Enhanced autocmds for blog writing and development workflow
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- ════════════════════════════════════════════════════════════════
-- 📝 BLOG WRITING AUTOMATIONS
-- ════════════════════════════════════════════════════════════════

-- Auto-set blog metadata when creating new markdown files in blog directory
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*/wiki/my_blog/**/*.md",
  callback = function()
    local filename = vim.fn.expand("%:t:r")
    local date = os.date("%Y-%m-%d")
    local template = string.format(
      [[
---
title: "%s"
date: %s
draft: true
tags: []
---

# %s

]],
      filename:gsub("-", " "):gsub("_", " "),
      date,
      filename:gsub("-", " "):gsub("_", " ")
    )

    vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
    vim.api.nvim_win_set_cursor(0, { 7, 0 }) -- Position cursor after title
  end,
})

-- -- Close Outline when the last Markdown window/buffer is closed
-- local function close_outline_windows()
--   -- Try the plugin command first if available
--   pcall(vim.cmd, "OutlineClose")
--   -- Fallback: close any window whose buffer filetype looks like Outline
--   for _, win in ipairs(vim.api.nvim_list_wins()) do
--     local buf = vim.api.nvim_win_get_buf(win)
--     local ft = vim.bo[buf].filetype
--     if ft == "Outline" or ft == "outline" then
--       pcall(vim.api.nvim_win_close, win, true)
--     end
--   end
-- end
--
-- local function any_markdown_windows_visible()
--   for _, win in ipairs(vim.api.nvim_list_wins()) do
--     local buf = vim.api.nvim_win_get_buf(win)
--     if vim.bo[buf].filetype == "markdown" then
--       return true
--     end
--   end
--   return false
-- end
--
-- local function any_loaded_markdown_buffers()
--   for _, buf in ipairs(vim.api.nvim_list_bufs()) do
--     if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
--       return true
--     end
--   end
--   return false
-- end
--
-- -- When leaving a Markdown window, if no Markdown windows remain, close Outline
-- vim.api.nvim_create_autocmd("BufWinLeave", {
--   pattern = { "*.md" },
--   callback = function()
--     if not any_markdown_windows_visible() then
--       close_outline_windows()
--     end
--   end,
-- })
--
-- -- When deleting a Markdown buffer, if no Markdown buffers remain, close Outline
-- vim.api.nvim_create_autocmd("BufDelete", {
--   pattern = { "*.md" },
--   callback = function()
--     if not any_loaded_markdown_buffers() then
--       close_outline_windows()
--     end
--   end,
-- })

-- ════════════════════════════════════════════════════════════════
-- 💾 SMART AUTO-SAVE ENHANCEMENTS
-- ════════════════════════════════════════════════════════════════

-- Save on focus lost (when switching applications)
vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" then
      vim.cmd("silent! write")
    end
  end,
})

-- ════════════════════════════════════════════════════════════════
-- 🎨 VISUAL ENHANCEMENTS
-- ════════════════════════════════════════════════════════════════

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
  end,
})

-- Ensure gruvbox transparency is maintained
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Force transparency for key elements
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
  end,
})

-- ════════════════════════════════════════════════════════════════
-- 📁 FILE MANAGEMENT
-- ════════════════════════════════════════════════════════════════

-- Auto-create directories when saving files
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local dir = vim.fn.expand("<afile>:p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- Clean trailing whitespace on save (except for markdown)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    if vim.bo.filetype ~= "markdown" then
      local save_cursor = vim.fn.getpos(".")
      local old_query = vim.fn.getreg("/")
      vim.cmd("silent! %s/\\s\\+$//e")
      vim.fn.setpos(".", save_cursor)
      vim.fn.setreg("/", old_query)
    end
  end,
})

-- ════════════════════════════════════════════════════════════════
-- 🔧 DEVELOPMENT WORKFLOW
-- ════════════════════════════════════════════════════════════════

-- Auto-reload config files when changed
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*/nvim/lua/**/*.lua",
  callback = function()
    vim.notify("🔄 Neovim config reloaded", vim.log.levels.INFO)
    -- Clear lua module cache
    for name, _ in pairs(package.loaded) do
      if name:match("^config") or name:match("^plugins") then
        package.loaded[name] = nil
      end
    end
  end,
})

-- ════════════════════════════════════════════════════════════════
-- 🗂️  PERSIST FOLDS AND CURSOR (save/load view)
-- ════════════════════════════════════════════════════════════════

-- Save view (folds/cursor) on write and buffer leave for normal files
vim.api.nvim_create_autocmd({ "BufWinLeave", "BufWritePost" }, {
  pattern = "*",
  callback = function()
    if vim.bo.buftype == "" and vim.bo.modifiable and vim.fn.expand("%") ~= "" then
      pcall(vim.cmd, "silent! mkview!")
    end
  end,
})

-- Load view (folds/cursor) when opening readable files
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",
  callback = function()
    if vim.bo.buftype == "" and vim.fn.expand("%") ~= "" and vim.fn.filereadable(vim.fn.expand("%:p")) == 1 then
      pcall(vim.cmd, "silent! loadview")
    end
  end,
})

-- ════════════════════════════════════════════════════════════════
-- 🎯 WINDOW MANAGEMENT
-- ════════════════════════════════════════════════════════════════

-- Auto-resize windows when terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "help",
    "startuptime",
    "qf",
    "lspinfo",
    "man",
    "checkhealth",
    "dbout",
    "gitsigns.blame",
    "null-ls-info",
    "DressingSelect",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- -- Auto-open outline for Markdown files
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "markdown" },
--   callback = function()
--     -- Avoid opening multiple times for the same buffer
--     if vim.b._outline_opened then
--       return
--     end
--     vim.b._outline_opened = true
--     -- Use pcall to avoid errors if plugin not loaded yet
--     pcall(function()
--       -- Prefer focusing main window and opening outline on the left
--       vim.cmd("OutlineOpen")
--     end)
--   end,
-- })
