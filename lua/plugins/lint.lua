-- ~/.config/nvim/lua/plugins/lint.lua
return {
	"mfussenegger/nvim-lint",
	optional = true,
	opts = {
		linters = {
			markdownlint = {
				args = {
					"--config",
					vim.fn.expand("~/.markdownlint-cli2.yaml"), -- Path to your config
				},
			},
		},
	},
}
