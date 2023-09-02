

require('mason').setup()
local mason_lsp = require('mason-lspconfig')

mason_lsp.setup({
  ensure_installed = {
    'clangd',
  }
})

local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
local lsp_attach = function(client, buffer)
  local opts = {buffer = buffer, remap = false}

  vim.lsp.inlay_hint(buffer, true)

  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, opts)
  vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, opts)
  vim.keymap.set("n", "go", function() vim.lsp.buf.type_definition() end, opts)
  vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "gs", function() vim.lsp.buf.signature_help() end, opts)
  vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "<leader>=", function() vim.lsp.buf.format() end, opts)
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
end



local lspconfig = require('lspconfig')
mason_lsp.setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({
      on_attach = lsp_attach,
      capabilities = lsp_capabilities,
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
          },
          diagnostics = {
            globals = {
              'vim',
            },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
        },
      }
    })
  end,
})

-- This shit doesn't work.  The client doesnt connect to the buffer
--
-- require('lspconfig').sourcekit.setup{
--   cmd = {'/opt/swift/bin/sourcekit-lsp'},
--   filetypes = {'swift'}
-- }
-- 
-- vim.api.nvim_create_autocmd('LspAttach',
-- {
--  -- pattern = {"*.swift"},
--   callback = function(ev)
--     print(string.format("lspattach: %s (%s) ", ev.event, ev.file))
--   end,
-- })

--vim.api.nvim_create_autocmd('LspAttach', {
--  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
--  callback = function(ev)
--    print("group attach", ev)
--  end,
--})

--vim.lsp.set_log_level("debug")

