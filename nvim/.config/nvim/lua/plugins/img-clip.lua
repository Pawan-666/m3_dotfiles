return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      dir_path = "/Users/pawan/test/my-blog/content/images",
      file_name = "%Y-%m-%d-%H-%M-%S", -- string, not boolean
    },
  },
  config = function(_, opts)
    require("img-clip").setup(opts)
  end,
}
