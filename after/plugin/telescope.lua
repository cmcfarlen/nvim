local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)

vim.keymap.set('n', '<leader>ws', builtin.lsp_dynamic_workspace_symbols, {})

require('telescope').setup {
  extensions = {
    ["ui-select"] = {}
  }
}

require("telescope").load_extension("ui-select")
