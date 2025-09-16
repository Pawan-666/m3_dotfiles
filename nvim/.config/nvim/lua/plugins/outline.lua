return {
  "hedyhli/outline.nvim",
  cmd = { "Outline", "OutlineOpen", "OutlineFocus" },
  keys = {
    { "<leader>O", "<cmd>Outline<CR>", desc = "Toggle outline" },
  },
  opts = {
    providers = {
      priority = { "lsp", "markdown" },
    },
    outline_window = {
      position = "right",
      -- position = "left",
      width = 35,
    },
  },
}
