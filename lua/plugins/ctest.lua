return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-lua/plenary.nvim",
		-- Other neotest dependencies here
		"nvim-treesitter/nvim-treesitter",
		"orjangj/neotest-ctest",
		"Shatur/neovim-tasks",
		"rosstang/lunajson.nvim",
		--{ "rosstang/neotest-catch2", branch = "use-catch2-with-json" },
		{
			"neotest-swift",
			url = "git@github.pie.apple.com:jerryjrchen/neotest-swift.git",
		},
	},
	config = function()
		-- Optional, but recommended, if you have enabled neotest's diagnostic option
		local neotest_ns = vim.api.nvim_create_namespace("neotest")
		vim.diagnostic.config({
			virtual_text = {
				format = function(diagnostic)
					-- Convert newlines, tabs and whitespaces into a single whitespace
					-- for improved virtual text readability
					local message = diagnostic.message:gsub("[\r\n\t%s]+", " ")
					return message
				end,
			},
		}, neotest_ns)
		local lib = require("neotest.lib")

		require("neotest").setup({
			--log_level = vim.log.levels.DEBUG,
			adapters = {
				require("neotest-ctest").setup({}),
				-- Load with default config
				--require("neotest-catch2")(),
				require("neotest-swift"),
			},
			projects = {
				["~/projects/oss/trafficserver"] = {
					discovery = {
						enabled = true,
						concurrent = 0,
						filter_dir = function(name, rel_path, root)
							return name ~= "build"
						end,
					},
					adapters = {
						require("neotest-ctest").setup({
							frameworks = { "catch2" },
							is_test_file = function(file_path)
								local elems = vim.split(file_path, lib.files.sep, { plain = true })
								local name, extension = unpack(vim.split(elems[#elems], ".", { plain = true }))
								local supported_extensions = { "cpp", "cc", "cxx" }
								return vim.tbl_contains(supported_extensions, extension)
										and (vim.startswith(name, "test_") or vim.endswith(name, "_test"))
									or false
							end,
						}),
					},
				},
			},
		})
	end,
}
