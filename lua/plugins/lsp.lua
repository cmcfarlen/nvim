return {
	{
		"neovim/nvim-lspconfig",
		init = function()
			local keys = require("lazyvim.plugins.lsp.keymaps").get()

			-- vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
			-- vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
			-- vim.keymap.set("n", "<leader>=", function() vim.lsp.buf.format() end, opts)
			-- vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
			-- vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)

			keys[#keys + 1] = {
				"gd",
				vim.lsp.buf.definition,
			}
			keys[#keys + 1] = {
				"gD",
				vim.lsp.buf.declaration,
			}
			keys[#keys + 1] = {
				"gi",
				vim.lsp.buf.implementation,
			}
			keys[#keys + 1] = {
				"go",
				vim.lsp.buf.type_definition,
			}
			-- keys[#keys + 1] = {
			-- 	"gs",
			-- 	vim.lsp.buf.typehierarchy,
			-- }
			-- keys[#keys + 1] = {
			-- 	"gS",
			-- 	function()
			-- 		vim.lsp.buf.typehierarchy("supertypes")
			-- 	end,
			-- }
			keys[#keys + 1] = {
				"gr",
				vim.lsp.buf.references,
			}
			keys[#keys + 1] = {
				"gh",
				vim.lsp.buf.signature_help,
			}

			vim.diagnostic.config({
				virtual_text = true,
			})
		end,
		opts = {
			inlay_hints = {
				enabled = true,
			},
			servers = {
				sourcekit = {
					filetypes = { "swift", "objc", "objcpp" },
					capabilities = {
						workspace = {
							didChangeWatchedFiles = {
								dynamicRegistration = true,
							},
						},
					},
				},
			},
		},
	},
}
