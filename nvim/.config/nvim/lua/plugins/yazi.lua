return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  opts = {
    open_for_directories = true,
    keymaps = {
      open_file_in_vertical_split = "<C-l>",
      open_file_in_horizontal_split = "<C-j>",
      open_file_in_tab = "<C-t>",
      -- grep_in_directory = "<C-s>",
      replace_in_directory = "<C-g>",
      -- cycle_open_buffers = "<Tab>",
      -- copy_relative_path_to_selected_files = "<C-y>",
      -- send_to_quickfix_list = "<C-q>",
      -- change_working_directory = "<C-\\>",
    },
  },
  config = function(_, opts)
    require("yazi").setup(opts)

    -- Optional: Keybinding to launch Yazi
    vim.keymap.set("n", "<C-t>", "<cmd>Yazi<CR>", { desc = "Open Yazi File Manager" })
  end,
}
