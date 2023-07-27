local lsp = require('lsp-zero')

-- lsp.preset({
--   name = 'minimal',
--   set_lsp_keymaps = true,
--   manage_nvim_cmp = true,
--   suggest_lsp_servers = false,
-- })
--

lsp.preset('recommended')

-- (Optional) Configure lua language server for neovim
lsp.nvim_workspace()

lsp.setup()
