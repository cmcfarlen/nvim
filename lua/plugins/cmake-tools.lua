return {
	"Civitasv/cmake-tools.nvim",
	opts = {
		cmake_dap_configuration = { -- debug settings for cmake
			name = "cpp",
			type = "lldb",
			request = "launch",
			stopOnEntry = false,
			runInTerminal = false,
			-- cmake-tools defaults this to "integratedTerminal", and a deep merge keeps
			-- that default unless it is named here. lldb-dap honors console over
			-- runInTerminal, so leaving it out makes it launch through the
			-- runInTerminal helper, which times out. Keep program output in the REPL.
			console = "internalConsole",
		},
	},
}
