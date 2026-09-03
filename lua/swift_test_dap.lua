-- Adds a dap strategy to neotest-swift, which has none: <leader>td otherwise
-- reports "Adapter doesn't support chosen strategy".
--
-- What gets debugged differs by platform, so the .xctest artifact decides:
--
--   macOS  SwiftPM links a bundle, which cannot be executed. The toolchain's
--          swiftpm-testing-helper dlopens it and runs the swift-testing entry
--          point, and it needs Testing.framework on DYLD_FRAMEWORK_PATH.
--   Linux  The artifact is an executable and runs directly, no helper, no env.
--
-- Both take --filter and the event-stream flags, so neotest-swift's own results
-- parsing keeps working after a debug run.

local M = {}

---@async
---Run a command and collect both streams. Reading them concurrently avoids the
---deadlock where one pipe fills while the other is being drained.
---
---Everything here goes through nio rather than vim.system: after an async call
---the coroutine resumes in a fast event context, where vim.system():wait() dies
---on "vim.wait must not be called in a fast event context".
---@return integer? code, string stdout, string stderr
local function run(cmd, args, cwd)
	local nio = require("nio")
	local process, err = nio.process.run({ cmd = cmd, args = args, cwd = cwd })

	if not process then
		return nil, "", "could not start " .. cmd .. ": " .. tostring(err)
	end

	local out, errout = "", ""
	nio.gather({
		function()
			out = process.stdout.read() or ""
		end,
		function()
			errout = process.stderr.read() or ""
		end,
	})

	return process.result(true), out, errout
end

---@async
local function swift(args, cwd)
	return run("swift", args, cwd)
end

---The built test artifact: a bundle directory on macOS, an executable on Linux.
---@param bin_path string
---@return string? path, string? kind "bundle"|"executable"
local function find_test_artifact(bin_path)
	if not vim.uv.fs_stat(bin_path) then
		return nil
	end

	for name, kind in vim.fs.dir(bin_path) do
		if name:match("%.xctest$") then
			local path = bin_path .. "/" .. name

			if kind == "directory" then
				-- The executable inside the bundle shares the bundle's basename.
				local exe = path .. "/Contents/MacOS/" .. (name:gsub("%.xctest$", ""))
				if vim.uv.fs_access(exe, "X") then
					return exe, "bundle"
				end
			elseif vim.uv.fs_access(path, "X") then
				return path, "executable"
			end
		end
	end

	return nil
end

local macos_paths = nil

---@async
---swiftpm-testing-helper and Testing.framework, both outside the SDK.
---@return table? paths, string? error
local function macos_toolchain()
	if macos_paths then
		return macos_paths
	end

	-- xcrun -f rather than exepath: `swift` on PATH is /usr/bin/swift, the xcrun
	-- shim, so walking up from it lands outside the toolchain.
	local _, swift_bin = run("xcrun", { "-f", "swift" })
	local _, platform = run("xcrun", { "--show-sdk-platform-path" })
	local bin, sdk = vim.trim(swift_bin), vim.trim(platform)

	if bin == "" or sdk == "" then
		return nil, "could not locate the active Xcode toolchain via xcrun"
	end

	local helper = vim.fs.dirname(vim.fs.dirname(bin)) .. "/libexec/swift/pm/swiftpm-testing-helper"
	if not vim.uv.fs_access(helper, "X") then
		return nil, "swiftpm-testing-helper not found at " .. helper
	end

	macos_paths = { helper = helper, frameworks = sdk .. "/Developer/Library/Frameworks" }
	return macos_paths
end

---@async
---@param spec neotest.RunSpec
---@param dap_adapter string
---@return table? strategy, string? error
local function dap_strategy(spec, dap_adapter)
	local root = spec.cwd

	if not root then
		return nil, "no package root in the run spec"
	end

	local code, _, build_err = swift({ "build", "--build-tests" }, root)
	if code ~= 0 then
		return nil, "swift build --build-tests failed:\n" .. build_err
	end

	-- --show-bin-path rather than .build/debug: honors --scratch-path, the build
	-- configuration and the target triple.
	local bin_code, bin_out = swift({ "build", "--show-bin-path" }, root)
	local bin_path = vim.trim(bin_out)
	if bin_code ~= 0 or bin_path == "" then
		return nil, "could not determine the build directory"
	end

	local artifact, kind = find_test_artifact(bin_path)
	if not artifact then
		return nil, "no built .xctest artifact under " .. bin_path
	end

	local args = {}
	local program = artifact
	local env = nil

	if kind == "bundle" then
		local paths, err = macos_toolchain()
		if not paths then
			return nil, err
		end
		program = paths.helper
		env = { "DYLD_FRAMEWORK_PATH=" .. paths.frameworks }
		-- The helper wants the path twice: once for itself, once for the entry point.
		args = { "--test-bundle-path", artifact, artifact }
	end

	vim.list_extend(args, { "--testing-library", "swift-testing" })

	for _, id in ipairs(spec.context and spec.context.test_identifiers or {}) do
		vim.list_extend(args, { "--filter", id })
	end

	if spec.context and spec.context.event_stream_file then
		vim.list_extend(args, {
			"--event-stream-output-path",
			spec.context.event_stream_file,
			"--event-stream-version",
			"0",
		})
	end

	return {
		type = dap_adapter,
		request = "launch",
		name = "Debug swift test",
		program = program,
		args = args,
		cwd = root,
		env = env,
		console = "internalConsole",
		stopOnEntry = false,
	}
end

---Wrap neotest-swift with dap support.
---@param opts? { dap_adapter?: string }
---@return table?
function M.adapter(opts)
	local loaded, base = pcall(require, "neotest-swift")

	if not loaded then
		return nil
	end

	local dap_adapter = (opts or {}).dap_adapter or "lldb"

	local adapter = {}
	for key, value in pairs(base) do
		adapter[key] = value
	end

	adapter.build_spec = function(args)
		local spec = base.build_spec(args)

		if not spec or args.strategy ~= "dap" then
			return spec
		end

		local strategy, err = dap_strategy(spec, dap_adapter)
		if not strategy then
			vim.notify("neotest-swift dap: " .. err, vim.log.levels.ERROR)
			return nil
		end

		spec.strategy = strategy
		return spec
	end

	return adapter
end

return M
