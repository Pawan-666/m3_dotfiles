local is_wezterm = (vim.env.TERM_PROGRAM == "WezTerm")
  or (vim.env.WEZTERM_EXECUTABLE ~= nil)
  or (vim.env.WEZTERM_PANE ~= nil)

return {
  "folke/snacks.nvim",
  priority = 1000,
  opts = {
    dashboard = { enabled = false },
    styles = {
      snacks_image = {
        relative = "editor",
        col = -1,
      },
    },
    image = {
      enabled = true,
      -- Let Snacks auto-detect support; keep inline on and use float as fallback
      inline = { enabled = not is_wezterm },
      float = { enabled = true },
      -- Render only the image at cursor to avoid redraw glitches
      doc = {
        inline = not is_wezterm,
        float = true,
        only_render_image_at_cursor = true,
        max_width = 80,
        max_height = 50,
      },
      markdown = {
        enabled = true,
        -- render images inline in markdown buffers
        html = true,
        filetypes = { "markdown", "vimwiki" },
        only_render_image_at_cursor = true,
        -- Resolve site-root paths like "/images/foo.png" to your local repo path
        resolve = function(path, ctx)
          -- when using site-root links, point to your blog's static dir
          if path:sub(1, 8) == "/images/" then
            local static_dir = vim.fn.expand("~/wiki/my_blog/blog_site/static")
            return static_dir .. path
          end
          -- make relative links absolute based on current file
          if not path:match("^/") and ctx and ctx.buf then
            local file_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.buf), ":p:h")
            return file_dir .. "/" .. path
          end
          return path
        end,
      },
      view = { style = "snacks_image" },
      max_width = 60,
      max_height = 30,
    },
  },
}
