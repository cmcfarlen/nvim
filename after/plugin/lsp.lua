

require('mason').setup()
local mason_lsp = require('mason-lspconfig')

mason_lsp.setup({
  ensure_installed = {
    'clangd',
  }
})

local ts = require('telescope.builtin')

local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
local lsp_attach = function(server_name)
  return function(_, buffer)
    local opts = {buffer = buffer, remap = false}

    if server_name ~= "cmake" and server_name ~= "pyright" and server_name ~= "swift" and server_name ~= "jsonls" then
      vim.lsp.inlay_hint.enable(buffer, true)
    end

    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, opts)
    vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, opts)
    vim.keymap.set("n", "go", function() vim.lsp.buf.type_definition() end, opts)
    --vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "gr", ts.lsp_references, opts)
    vim.keymap.set("n", "gs", function() vim.lsp.buf.signature_help() end, opts)
    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set("n", "<leader>=", function() vim.lsp.buf.format() end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
  end
end



local lspconfig = require('lspconfig')
mason_lsp.setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({
      on_attach = lsp_attach(server_name),
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
        cmake = {
          buildDirectoyr = "cmake-build-debug-llvm-16"
        },
        json = {
          schemas = require('schemastore').json.schemas(),
          validate = { enable = true },
        },
      },
    })
  end,
})

local swift_lsp = vim.api.nvim_create_augroup("swift_lsp", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "swift" },
  callback = function(ev)
    local root_dir = vim.fs.dirname(vim.fs.find({
      "Package.swift",
      ".git",
    }, { upward = true })[1])
    local cmd = function ()
      if vim.fn.has('macunix') == 1 then
        return { 'xcrun', 'sourcekit-lsp' }
      else
        return { '/opt/swift/bin/sourcekit-lsp' }
      end
    end
    local client = vim.lsp.start({
      name = "sourcekit-lsp",
      cmd = cmd(),
      root_dir = root_dir,
      on_attach = lsp_attach("swift")
    })
    if client then
      vim.lsp.buf_attach_client(ev.buf, client)
    end
  end,
  group = swift_lsp,
})

