-- This require a jre to be installed
-- brew install pkl-lsp
-- https://github.com/apple/pkl-neovim
-- https://github.com/apple/pkl-lsp
-- https://pkl-lang.org/main/current/pkl-cli/index.html
--
-- I had to run TSInstall pkl manually
-- This require luasnip
return {
	{
		"apple/pkl-neovim",
		lazy = true,
		ft = "pkl",
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter",
				build = function(_)
					vim.cmd("TSUpdate")
				end,
			},
		},
		build = function()
			require("pkl-neovim").init()
		end,
		config = function()
			-- Configure pkl-lsp
			vim.g.pkl_neovim = {
				start_command = { "pkl-lsp" },
				--pkl_cli_path = "/patph/to/pkl",
			}
		end,
	},
}
