return {
  "vimichael/floatingtodo.nvim",
  config = function()
    require("floatingtodo").setup({
      target_file = "~/wiki/todo.md",
    })
    vim.keymap.set("n", "<leader>td", ":Td<CR>", { silent = true })
  end,
}
