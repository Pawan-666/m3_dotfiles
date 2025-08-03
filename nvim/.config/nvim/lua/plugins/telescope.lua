return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-telescope/telescope-ui-select.nvim",
  },
  keys = {
    -- Override default LazyVim keybindings
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
    { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
    { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
    { "<leader>fs", "<cmd>Telescope grep_string<cr>", desc = "Grep String" },
    { "<leader>fw", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Find in Buffer" },
    
    -- Custom keybindings
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    { "<leader>fq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix" },
    { "<leader>fl", "<cmd>Telescope loclist<cr>", desc = "Location List" },
    { "<leader>ft", "<cmd>Telescope treesitter<cr>", desc = "Treesitter Symbols" },
    { "<leader>fj", "<cmd>Telescope jumplist<cr>", desc = "Jump List" },
    { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks" },
    { "<leader>fp", "<cmd>Telescope registers<cr>", desc = "Registers" },
    
    -- Git integration
    { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
    { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
    { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
    { "<leader>gf", "<cmd>Telescope git_files<cr>", desc = "Git Files" },
    
    -- LSP integration
    { "<leader>lr", "<cmd>Telescope lsp_references<cr>", desc = "LSP References" },
    { "<leader>ld", "<cmd>Telescope lsp_definitions<cr>", desc = "LSP Definitions" },
    { "<leader>li", "<cmd>Telescope lsp_implementations<cr>", desc = "LSP Implementations" },
    { "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
    { "<leader>lw", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace Symbols" },
    
    -- Advanced searches
    { "<leader>f/", "<cmd>Telescope search_history<cr>", desc = "Search History" },
    { "<leader>f:", "<cmd>Telescope command_history<cr>", desc = "Command History" },
    { "<leader>f;", "<cmd>Telescope resume<cr>", desc = "Resume Last Search" },
    
    -- Blog-specific searches (for your content creation workflow)
    { 
      "<leader>fbb", 
      function() 
        require("telescope.builtin").find_files({ 
          cwd = "~/wiki/my_blog",
          prompt_title = "Find Blog Files" 
        }) 
      end, 
      desc = "Find Blog Files" 
    },
    { 
      "<leader>fbi", 
      function() 
        require("telescope.builtin").find_files({ 
          cwd = "~/wiki/my_blog/blog_site/static/images",
          prompt_title = "Find Blog Images" 
        }) 
      end, 
      desc = "Find Blog Images" 
    },
    { 
      "<leader>fbg", 
      function() 
        require("telescope.builtin").live_grep({ 
          cwd = "~/wiki/my_blog",
          prompt_title = "Search Blog Content" 
        }) 
      end, 
      desc = "Search Blog Content" 
    },
  },
  
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    
    telescope.setup({
      defaults = {
        -- UI customization
        prompt_prefix = " 🔍 ",
        selection_caret = " ❯ ",
        entry_prefix = "  ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
            results_width = 0.8,
          },
          vertical = {
            mirror = false,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
        
        -- Performance optimizations
        file_sorter = require("telescope.sorters").get_fuzzy_file,
        file_ignore_patterns = { 
          "%.git/", 
          "node_modules/", 
          "%.npm/",
          "%.next/",
          "dist/",
          "build/",
          "%.DS_Store",
          "%.png",
          "%.jpg",
          "%.jpeg", 
          "%.gif",
          "%.pdf",
          "%.zip",
          "%.tar.gz"
        },
        generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
        path_display = { "truncate" },
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        set_env = { ["COLORTERM"] = "truecolor" },
        
        -- Custom mappings
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-c>"] = actions.close,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<PageUp>"] = actions.results_scrolling_up,
            ["<PageDown>"] = actions.results_scrolling_down,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<C-l>"] = actions.complete_tag,
            ["<C-/>"] = actions.which_key,
          },
          n = {
            ["<esc>"] = actions.close,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["H"] = actions.move_to_top,
            ["M"] = actions.move_to_middle,
            ["L"] = actions.move_to_bottom,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["gg"] = actions.move_to_top,
            ["G"] = actions.move_to_bottom,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<PageUp>"] = actions.results_scrolling_up,
            ["<PageDown>"] = actions.results_scrolling_down,
            ["?"] = actions.which_key,
          },
        },
      },
      
      pickers = {
        -- Specific picker customizations
        find_files = {
          theme = "dropdown",
          previewer = false,
          hidden = true,
        },
        live_grep = {
          additional_args = function()
            return {"--hidden"}
          end
        },
        buffers = {
          theme = "dropdown",
          previewer = false,
          initial_mode = "normal",
        },
        help_tags = {
          theme = "ivy",
        },
        git_files = {
          theme = "dropdown",
          previewer = false,
        },
        oldfiles = {
          theme = "dropdown",
          previewer = false,
        },
      },
      
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({
            winblend = 10,
            width = 0.5,
            prompt = " ",
            results_height = 15,
            preview_cutoff = 40,
          }),
        },
      },
    })
    
    -- Load extensions
    telescope.load_extension("fzf")
    telescope.load_extension("ui-select")
  end,
}