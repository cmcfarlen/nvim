return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	event = {
		-- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
		-- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
		-- refer to `:h file-pattern` for more examples
		"BufReadPre "
			.. vim.fn.expand("~")
			.. "/vaults/apple/*.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/vaults/apple/*.md",
		"BufReadPre " .. vim.fn.expand("~") .. "/vaults/personal/*.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/vaults/personal/*.md",
		"BufReadPre " .. vim.fn.expand("~") .. "/projects/my/quartz/content/*.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/projects/my/quartz/content/*.md",
	},
	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",

		-- see below for full list of optional dependencies 👇
	},
	opts = {
		workspaces = {
			{
				name = "apple",
				path = "~/vaults/apple",
			},
			{
				name = "personal",
				path = "~/vaults/personal",
			},
			{
				name = "blog",
				path = "~/projects/my/quartz/content",
			},
		},
		daily_notes = {
			folder = "notes/journal",
			date_format = "%Y-%m-%d",
		},
		completion = {
			--nvim_cmp = true,
			min_chars = 2,
		},
		mappings = {
			-- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			-- Toggle check-boxes.
			["<leader>ch"] = {
				action = function()
					return require("obsidian").util.toggle_checkbox()
				end,
				opts = { buffer = true },
			},
			-- custom
			--["<leader>ot"] = {
			--  action = function()
			--    return require("obsidian").util.today()
			--  end,
			--  opts = { buffer = true },
			--},
			--["<leader>oy"] = {
			--  action = function()
			--    return require("obsidian").util.yesterday()
			--  end,
			--  opts = { buffer = true },
			--},
			--["<leader>os"] = {
			--  action = function()
			--    return require("obsidian").util.search()
			--  end,
			--  opts = { buffer = true },
			--},
			["<leader>ob"] = {
				action = function()
					return require("obsidian").util.backlinks()
				end,
				opts = { buffer = true },
			},
		},

		-- see below for full list of options 👇
	},
	keys = {
		{ "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Obsidian Today" },
		{ "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Obsidian Yesterday" },
		{ "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian Search" },
	},
}
