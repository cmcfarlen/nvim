local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
vim.keymap.set('n', '<leader>fm', function() builtin.man_pages{sections={'ALL'}} end, {})
vim.keymap.set('n', '<leader>fma', function() builtin.man_pages{sections={'ALL'}} end, {})
vim.keymap.set('n', '<leader>fm2', function() builtin.man_pages{sections={'2'}} end, {})
vim.keymap.set('n', '<leader>fm7', function() builtin.man_pages{sections={'7'}} end, {})
vim.keymap.set('n', '<leader>fgf', builtin.git_files, {})
vim.keymap.set('n', '<leader>fgc', builtin.git_commits, {})
vim.keymap.set('n', '<leader>fgb', builtin.git_branches, {})
vim.keymap.set('n', '<leader>fr', builtin.live_grep, {})
vim.keymap.set('n', '<leader>ws', builtin.lsp_dynamic_workspace_symbols, {})

require('telescope').setup {
  extensions = {
    ["ui-select"] = {}
  }
}

require("telescope").load_extension("ui-select")
