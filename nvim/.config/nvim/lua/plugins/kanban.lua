-- Kanban board plugin
return {
  "arakkkkk/kanban.nvim",
  lazy = false,
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("kanban").setup({
      markdown = {
        description_folder = "./tasks/",
        list_head = "## ",
      },
    })
  end,
}
