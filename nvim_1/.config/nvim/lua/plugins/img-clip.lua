return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      dir_path = "/Users/pawan/wiki/my_blog/blog_site/static/images",
      -- dir_path = "/Users/pawan/obsidian_pawan/images",
      file_name = "%Y-%m-%d-%H-%M-%S", -- string, not boolean
      process_cmd = "convert - -set gamma 0.4545 -",
    },
  },
  config = function(_, opts)
    require("img-clip").setup(opts)
  end,
}
