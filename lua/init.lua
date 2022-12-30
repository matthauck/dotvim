require("config.lsp").setup()

require("trouble").setup{
  use_diagnostic_signs = true
}


local actions = require("telescope.actions")
local action_layout = require("telescope.actions.layout")
require("telescope").setup{
  defaults = {
    theme = "dropdown",
    mappings = {
      n = {
        ["<M-p>"] = action_layout.toggle_preview,
      },
      i = {
        ["<M-p>"] = action_layout.toggle_preview,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      },
    },
  }
}
require('telescope').load_extension('fzf')
