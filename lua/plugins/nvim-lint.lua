local function sflinter()
	local pattern = "[^:]+:(%d+):(%d+): (%w+): (.+)"
	local groups = { "lnum", "col", "severity", "message" }
	local defaults = { ["source"] = "swiftlint" }
	local severity_map = {
		["error"] = vim.diagnostic.severity.ERROR,
		["warning"] = vim.diagnostic.severity.WARN,
	}
	return {
		name = "swiftlint",
		stdin = true,
		cmd = "swift",
		args = {
			"format",
			"lint",
		},
		stream = "both",
		ignore_exitcode = true,
		parser = require("lint.parser").from_pattern(pattern, groups, severity_map, defaults),
	}
end

return {
	"mfussenegger/nvim-lint",
	opts = {
		linters_by_ft = {
			swift = { "swiftformat" },
		},
		linters = {
			swiftformat = sflinter(),
		},
	},
}
