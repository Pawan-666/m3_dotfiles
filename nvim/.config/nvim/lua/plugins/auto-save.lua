return {
  "pocco81/auto-save.nvim",
  event = { "InsertLeave", "FocusLost", "BufLeave" }, -- optional lazy-loading
  config = function()
    require("auto-save").setup({
      enabled = true,
      execution_message = {
        message = function()
          -- return "AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S")
          return ""
        end,
        dim = 0.18,
        cleaning_interval = 1250,
      },
      -- not TextChanged: that saved on every normal-mode edit (x, dd, p...),
      -- re-running formatters/LSP/watchers each time. FocusLost needs tmux's
      -- focus-events on.
      trigger_events = { "InsertLeave", "FocusLost", "BufLeave" },
      conditions = {
        exists = true,
        filename_is_not = {},
        filetype_is_not = { "neo-tree", "lazy", "toggleterm", "NvimTree" },
        modifiable = true,
      },
    })
  end,
}
