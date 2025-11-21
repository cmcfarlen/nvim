return {
	{
		"neovim/nvim-lspconfig",
		init = function()
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
				-- clangd = {
				-- 	-- This is the key part for your exact use-case:
				-- 	single_file_support = true, -- allows clangd on buffers with no file
				--
				-- 	-- Make sure root_dir resolves even when no buffer is open
				-- 	root_dir = function(fname)
				-- 		-- fname is "" when no file is open yet → fallback to cwd
				-- 		return require("lspconfig.util").root_pattern(
				-- 			"compile_commands.json",
				-- 			"compile_flags.txt",
				-- 			".clangd",
				-- 			"CMakeLists.txt",
				-- 			".git",
				-- 			"BUILD.bazel",
				-- 			"BUILD"
				-- 		)(fname or "") or vim.fn.getcwd()
				-- 	end,
				-- 	auto_start = true,
				--
				-- 	-- cmd = {
				-- 	--   "clangd",
				-- 	--   "--background-index",
				-- 	--   "--clang-tidy",           -- optional but nice
				-- 	--   "--header-insertion=iwyu",
				-- 	--   "--completion-style=detailed",
				-- 	--   "--function-arg-placeholders",
				-- 	--   "--fallback-style=llvm",
				-- 	-- },
				--
				-- 	init_options = {
				-- 		usePlaceholders = true,
				-- 		completeUnimported = true,
				-- 		clangdFileStatus = true,
				-- 	},
				--
				-- 	-- Optional: if you don’t always have compile_commands.json
				-- 	-- fallbackFlags = { "-std=c++23" },
				-- },
			},
		},
		keys = {
			-- vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
			-- vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
			-- vim.keymap.set("n", "<leader>=", function() vim.lsp.buf.format() end, opts)
			-- vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
			-- vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
			-- { "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", has = "definition" },
			-- { "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", has = "declaration" },
			-- { "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", has = "implementation" },
			-- { "go", "<cmd>lua vim.lsp.buf.type_definition()<CR>", has = "type_definition" },
			-- { "gr", "<cmd>lua vim.lsp.buf.references()<CR>", has = "references" },
			-- { "gh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", has = "signature_help" },
			-- { "gs", "<cmd>lua vim.lsp.buf.typehierarchy()<CR>", has = "typehierarchy" },
			-- { "gS", "<cmd>lua vim.lsp.buf.typehierarchy('supertypes')<CR>", has = "supertypes" },
		},
	},
}
