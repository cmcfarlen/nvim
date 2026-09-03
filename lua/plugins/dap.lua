-- All nvim-dap setup: the lldb adapter, Swift and C/C++ configurations, CMake
-- target debugging, and single-key stepping while a session is running.
--
-- LazyVim's own dap.core extra owns the plugin itself and the <leader>d keymaps;
-- this only adds to it.
return {
	"mfussenegger/nvim-dap",
	optional = true,
	opts = function()
		local dap = require("dap")

		vim.keymap.set("n", "<leader>dL", function()
			require("dap.repl").open_logfile()
		end, { desc = "DAP Open Logfile" })

		--- Adapter ----------------------------------------------------------------

		-- Xcode ships lldb-dap, so there is nothing to install through mason.
		if not dap.adapters.lldb then
			local xcode_path = vim.fn.trim(vim.fn.system("xcode-select -p"))
			dap.adapters.lldb = {
				type = "executable",
				command = xcode_path .. "/usr/bin/lldb-dap",
				name = "lldb",
			}
		end

		--- Swift ------------------------------------------------------------------

		-- SwiftPM writes dependency-resolution progress to stderr, so read stdout on
		-- its own. vim.fn.system merges the two and would hand back that chatter as
		-- though it were output.
		local function swift_run(args, root, on_done)
			vim.system(vim.list_extend({ "swift" }, args), { cwd = root, text = true }, function(result)
				vim.schedule(function()
					on_done(result)
				end)
			end)
		end

		local function swift_package_root()
			local from = vim.api.nvim_buf_get_name(0)
			local marker = vim.fs.find({ "Package.swift" }, {
				-- vim.uv.cwd rather than vim.fn.getcwd: this can run in a fast event.
				path = from ~= "" and vim.fs.dirname(from) or vim.uv.cwd(),
				upward = true,
			})[1]

			return marker and vim.fs.dirname(marker) or nil
		end

		-- Pick an executable product, build it, and hand back the built binary. nvim-dap
		-- resumes a returned suspended coroutine, which is what lets this be async.
		local function pick_swift_program()
			return coroutine.create(function(dap_co)
				local function finish(value)
					coroutine.resume(dap_co, value)
				end

				-- vim.ui.select and vim.fn.input are not allowed in a fast event context.
				vim.schedule(function()
					local root = swift_package_root()

					if not root then
						return finish(vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file"))
					end

					local function launch(name)
						vim.notify("swift build --product " .. name, vim.log.levels.INFO)

						swift_run({ "build", "--product", name }, root, function(build)
							if build.code ~= 0 then
								-- SwiftPM splits diagnostics across both streams, so show either.
								local why = vim.trim((build.stderr or "") .. "\n" .. (build.stdout or ""))
								vim.notify("swift build failed:\n" .. why, vim.log.levels.ERROR)
								return finish(dap.ABORT)
							end

							swift_run({ "build", "--show-bin-path" }, root, function(bin)
								local dir = vim.trim(bin.stdout or "")
								local exe = dir ~= "" and (dir .. "/" .. name) or nil

								if not exe or not vim.uv.fs_access(exe, "X") then
									vim.notify("Not found after build: " .. tostring(exe), vim.log.levels.ERROR)
									return finish(dap.ABORT)
								end
								finish(exe)
							end)
						end)
					end

					swift_run({ "package", "completion-tool", "list-executables" }, root, function(result)
						local names = {}
						for line in (result.stdout or ""):gmatch("[^\r\n]+") do
							local name = vim.trim(line)
							if name ~= "" then
								table.insert(names, name)
							end
						end

						if #names == 0 then
							vim.notify("No executable products in " .. root, vim.log.levels.ERROR)
							return finish(dap.ABORT)
						end
						if #names == 1 then
							return launch(names[1])
						end

						vim.ui.select(names, { prompt = "Swift executable" }, function(choice)
							-- Cancelling must still resume, or dap waits forever.
							if not choice then
								return finish(dap.ABORT)
							end
							launch(choice)
						end)
					end)
				end)
			end)
		end

		dap.configurations.swift = {
			{
				name = "Launch executable product",
				type = "lldb",
				request = "launch",
				program = pick_swift_program,
				-- The package root, not nvim's cwd, so a launched binary resolves relative
				-- paths the way `swift run` would.
				cwd = function()
					return swift_package_root() or vim.uv.cwd()
				end,
				stopOnEntry = false,
			},
		}

		--- C/C++ -----------------------------------------------------------------

		-- The launch target is nil until one has been selected, and handing dap a nil
		-- program fails deep inside the adapter instead of here.
		local launch_target_path = function()
			local ok, cmake = pcall(require, "cmake-tools")
			local path = ok and cmake.get_launch_target_path() or nil

			if not path then
				vim.notify("No CMake launch target selected (<leader>dT)", vim.log.levels.WARN)
				return dap.ABORT
			end
			return path
		end

		-- This replaces the codelldb configurations LazyVim's lang.clangd extra sets,
		-- because this file loads after it. Attach is carried over from there, since
		-- attaching to a running traffic_server is worth keeping.
		local cpp_configurations = {
			{
				name = "Launch CMake target",
				type = "lldb",
				request = "launch",
				program = launch_target_path,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
			{
				name = "Attach to process",
				type = "lldb",
				request = "attach",
				pid = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		}

		-- dap.configurations is keyed by filetype, so cpp and c each need an entry.
		-- Separate copies: mason-nvim-dap appends its own entries per filetype, and a
		-- shared table would collect each of them twice.
		dap.configurations.cpp = cpp_configurations
		dap.configurations.c = vim.deepcopy(cpp_configurations)

		--- CMake target debugging -------------------------------------------------

		-- cmake.debug() builds the target first and derives program, cwd, args and env
		-- from the code model, so prefer it over dap.continue() for CMake projects.
		local debug_selected_target = function()
			local cmake = require("cmake-tools")
			local target = cmake.get_launch_target()

			-- Say which one, since the selection persists across restarts and is easy
			-- to forget. With none selected, cmake.debug() prompts and records it.
			if target then
				vim.notify("Debugging " .. target, vim.log.levels.INFO)
			end

			cmake.debug({})
		end

		-- Pick through cmake-tools rather than a local picker so the choice is stored
		-- as the launch target, which makes it sticky for <leader>dd and is persisted
		-- to the cmake-tools session. Cancelling just never invokes the callback.
		local debug_picked_target = function()
			local cmake = require("cmake-tools")

			cmake.select_launch_target(false, function(result)
				if result and result.is_ok and not result:is_ok() then
					return
				end
				debug_selected_target()
			end)
		end

		vim.keymap.set("n", "<leader>dd", debug_selected_target, { desc = "Debug CMake Target (build first)" })
		vim.keymap.set("n", "<leader>dT", debug_picked_target, { desc = "Pick CMake Target and Debug" })

		--- Session keys ------------------------------------------------------------

		-- Stepping is frequent enough that <leader>d<key> gets tiring, so the arrows
		-- become single-press steps for as long as a session is running. nvim-dap has
		-- no keymap-layer concept, so install on session start and put back whatever
		-- was there on session end.
		local STEP_KEYS = {
			{ lhs = "<Down>", fn = "step_into", desc = "DAP Step Into" },
			{ lhs = "<Up>", fn = "step_out", desc = "DAP Step Out" },
			{ lhs = "<Right>", fn = "step_over", desc = "DAP Step Over" },
		}

		-- K is what everyone reaches for, but LSP owns it: it maps K buffer-locally on
		-- attach, and a buffer-local map wins over a global one. So the debug hover has
		-- to be installed per buffer, in each buffer the debugger walks into.
		local HOVER_KEY = "K"
		local hovered = nil
		local hover_group = nil

		local function install_hover(buf)
			buf = buf or vim.api.nvim_get_current_buf()

			if not hovered or hovered[buf] ~= nil or not vim.api.nvim_buf_is_valid(buf) then
				return
			end

			local previous = vim.api.nvim_buf_call(buf, function()
				return vim.fn.maparg(HOVER_KEY, "n", false, true)
			end)

			-- Only a buffer-local map needs restoring; a global one was never shadowed.
			hovered[buf] = (previous and previous.buffer == 1) and previous or false

			vim.keymap.set("n", HOVER_KEY, function()
				require("dapui").eval()
			end, { buffer = buf, desc = "DAP Eval Under Cursor" })
		end

		local shadowed = nil

		local function install_session_keys()
			if shadowed then
				return
			end

			shadowed = {}
			for _, key in ipairs(STEP_KEYS) do
				local previous = vim.fn.maparg(key.lhs, "n", false, true)
				table.insert(shadowed, {
					lhs = key.lhs,
					previous = not vim.tbl_isempty(previous) and previous or nil,
				})
				vim.keymap.set("n", key.lhs, function()
					dap[key.fn]()
				end, { desc = key.desc })
			end

			hovered = {}
			hover_group = vim.api.nvim_create_augroup("dap_session_keys", { clear = true })
			vim.api.nvim_create_autocmd("BufEnter", {
				group = hover_group,
				callback = function(event)
					install_hover(event.buf)
				end,
			})
			install_hover()
		end

		local function remove_session_keys()
			-- Deferred, so nvim-dap has cleared the session before we ask. A nested
			-- session still running means the layer should stay.
			if not shadowed or dap.session() then
				return
			end

			for _, key in ipairs(shadowed) do
				if key.previous then
					pcall(vim.fn.mapset, key.previous)
				else
					pcall(vim.keymap.del, "n", key.lhs)
				end
			end
			shadowed = nil

			-- mapset applies to the current buffer, so restore each map where it came from.
			for buf, previous in pairs(hovered or {}) do
				if vim.api.nvim_buf_is_valid(buf) then
					pcall(vim.keymap.del, "n", HOVER_KEY, { buffer = buf })
					if previous then
						vim.api.nvim_buf_call(buf, function()
							pcall(vim.fn.mapset, previous)
						end)
					end
				end
			end
			hovered = nil

			if hover_group then
				pcall(vim.api.nvim_del_augroup_by_id, hover_group)
				hover_group = nil
			end
		end

		dap.listeners.after.event_initialized["session_keys"] = install_session_keys
		-- The buffer dap jumps to on each stop may be newly loaded.
		dap.listeners.after.event_stopped["session_keys"] = function()
			vim.schedule(function()
				install_hover()
			end)
		end
		for _, event in ipairs({ "event_terminated", "event_exited", "disconnect" }) do
			dap.listeners.after[event]["session_keys"] = function()
				vim.schedule(remove_session_keys)
			end
		end
	end,
}
