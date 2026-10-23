-- tailwindcss-language-server is installed and auto-enabled, and its default
-- filetypes include markdown, so it spawned a node server for every notes
-- buffer. Limit it to web files.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tailwindcss = {
        filetypes = {
          "html",
          "css",
          "scss",
          "sass",
          "less",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
          "svelte",
          "astro",
        },
      },
    },
  },
}
