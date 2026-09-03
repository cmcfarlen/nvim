-- Adds a dap strategy to neotest-swift, which has none: <leader>td otherwise
-- reports "Adapter doesn't support chosen strategy".
--
-- SwiftPM links the test bundle with -bundle, so it is not executable and cannot
-- be handed to lldb directly. The toolchain's swiftpm-testing-helper dlopens the
-- bundle and runs the swift-testing entry point, so that is what gets debugged.
-- It needs Testing.framework on DYLD_FRAMEWORK_PATH, which SwiftPM normally
-- sets itself.
--
-- The event-stream flags are passed through as well, so neotest-swift's own
-- results parsing still works after a debug run.

local M = {}

local toolchain = nil

local function xcode_toolchain()
	if toolchain then
		return toolchain
	end

	-- vim.system rather than vim.fn.system: no fast-event restriction, and stderr
	-- stays out of the result.
	local result = vim.system({ "xcode-select", "-p" }, { text = true }):wait()
	local developer = vim.trim(result.stdout or "")

	if developer == "" then
		return nil
	end

	toolchain = {
		helper = developer .. "/Toolchains/XcodeDefault.xctoolchain/usr/libexec/swift/pm/swiftpm-testing-helper",
		frameworks = developer .. "/Platforms/MacOSX.platform/Developer/Library/Frameworks",
	}
	return toolchain
end

---The executable inside the .xctest bundle, which shares the bundle's basename.
---@param root string
---@return string?
local function find_test_executable(root)
	local debug_dir = root .. "/.build/debug"

	if not vim.uv.fs_stat(debug_dir) then
		return nil
	end

	for name in vim.fs.dir(debug_dir) do
		if name:match("%.xctest$") then
			local exe = debug_dir .. "/" .. name .. "/Contents/MacOS/" .. (name:gsub("%.xctest$", ""))
			if vim.uv.fs_access(exe, "X") then
				return exe
			end
		end
	end

	return nil
end

---@async
---@param root string
---@return boolean ok, string? error
local function build_tests(root)
	local nio = require("nio")
	local process, err = nio.process.run({
		cmd = "swift",
		args = { "build", "--build-tests" },
		cwd = root,
	})

	if not process then
		return false, "could not start swift build: " .. tostring(err)
	end

	local output = process.stderr.read() or ""
	local code = process.result(true)

	if code ~= 0 then
		return false, "swift build --build-tests failed:\n" .. output
	end
	return true
end

---@async
---@param spec neotest.RunSpec
---@return table? strategy, string? error
local function dap_strategy(spec)
	local paths = xcode_toolchain()

	if not paths or not vim.uv.fs_access(paths.helper, "X") then
		return nil, "swiftpm-testing-helper not found in the active Xcode toolchain"
	end

	local root = spec.cwd
	if not root then
		return nil, "no package root in the run spec"
	end

	local ok, err = build_tests(root)
	if not ok then
		return nil, err
	end

	local exe = find_test_executable(root)
	if not exe then
		return nil, "no built .xctest bundle under " .. root .. "/.build/debug"
	end

	-- The helper wants the bundle path twice: once for --test-bundle-path and once
	-- as the argument the swift-testing entry point inspects.
	local args = { "--test-bundle-path", exe, exe, "--testing-library", "swift-testing" }

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
		type = "lldb",
		request = "launch",
		name = "Debug swift test",
		program = paths.helper,
		args = args,
		cwd = root,
		env = { "DYLD_FRAMEWORK_PATH=" .. paths.frameworks },
		console = "internalConsole",
		stopOnEntry = false,
	}
end

---Wrap neotest-swift with dap support.
---@return table?
function M.adapter()
	local loaded, base = pcall(require, "neotest-swift")

	if not loaded then
		return nil
	end

	local adapter = {}
	for key, value in pairs(base) do
		adapter[key] = value
	end

	adapter.build_spec = function(args)
		local spec = base.build_spec(args)

		if not spec or args.strategy ~= "dap" then
			return spec
		end

		local strategy, err = dap_strategy(spec)
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
