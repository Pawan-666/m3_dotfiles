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
    local template = string.format([[
---
title: "%s"
date: %s
draft: true
tags: []
---

# %s

]], filename:gsub("-", " "):gsub("_", " "), date, filename:gsub("-", " "):gsub("_", " "))
    
    vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
    vim.api.nvim_win_set_cursor(0, {7, 0}) -- Position cursor after title
  end,
})

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
    "help", "startuptime", "qf", "lspinfo", "man", "checkhealth",
    "dbout", "gitsigns.blame", "null-ls-info", "DressingSelect"
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})
