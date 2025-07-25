return {
	"mfussenegger/nvim-dap",
	optional = true,
	dependencies = "williamboman/mason.nvim",
	opts = function()
		local dap = require("dap")
		dap.set_log_level("TRACE")
		vim.keymap.set("n", "<leader>dL", function()
			require("dap.repl").open_logfile()
		end, { desc = "DAP Open Logfile" })
		local find_swift_bindir = function()
			return vim.fn.system({ "swift", "build", "--show-bin-path" })
		end
		local find_targets = function()
			return vim.fn.system({ "swift", "package", "completion-tool", "list-executables" })
		end

		if not dap.adapters.lldb then
			local xcode_path = vim.fn.trim(vim.fn.system("xcode-select -p"))
			dap.adapters.lldb = {
				type = "executable",
				command = xcode_path .. "/usr/bin/lldb-dap",
				name = "lldb",
			}
		end

		if not dap.adapters.cppdbg then
			local xcode_path = vim.fn.trim(vim.fn.system("xcode-select -p"))
			dap.adapters.cppdbg = {
				type = "executable",
				command = xcode_path .. "/usr/bin/lldb-dap",
				name = "cppdbg",
			}
		end

		dap.configurations.swift = {
			{
				name = "Launch file",
				type = "lldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", find_swift_bindir() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}
		dap.configurations.cpp = {
			{
				name = "Launch file",
				type = "lldb",
				request = "launch",
				program = require("cmake-tools").get_launch_target_path,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}
		dap.configurations.cppdbg = {
			{
				name = "Launch file",
				type = "lldb",
				request = "launch",
				program = require("cmake-tools").get_launch_target_path,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}
	end,
}
