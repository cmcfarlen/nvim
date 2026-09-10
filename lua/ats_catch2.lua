-- neotest adapter for Apache Traffic Server's Catch2 unit tests.
--
-- ATS registers one CTest test per test binary (the add_catch2_test macro in
-- lib/CMakeLists.txt calls add_test once per executable), so CTest has no name
-- for an individual TEST_CASE. neotest-ctest selects tests by CTest index, so
-- it can only ever run whole binaries: given a TEST_CASE name it matches
-- nothing and silently runs no tests at all.
--
-- Run the test binary directly instead, filtered to the selected cases, and
-- read results from Catch2's JUnit reporter.

local M = {}

-- add_catch2_test appends these to every test it registers: ATS test cases
-- expect declaration order, with setup in one TEST_CASE carrying into the next.
local CATCH2_ARGS = { "--order", "decl" }

local function project_root(source)
	local marker = vim.fs.find({ "CMakePresets.json", ".git" }, {
		path = vim.fs.dirname(source),
		upward = true,
	})[1]

	return marker and vim.fs.dirname(marker) or nil
end

---Build directories worth searching, best first.
---
---cmake-tools' selection comes first so an explicit choice wins, but it cannot be
---trusted on its own: with no configure preset selected it hands back its
---unexpanded default, e.g. "<root>/out/${variant:buildType}". A git worktree
---starts out in exactly that state. Fall back to configured build trees under the
---project root, newest first.
---@param source string
---@return string[]
local function candidate_build_dirs(source)
	local dirs, seen = {}, {}

	local function add(dir)
		if not dir or dir == "" or dir:find("${", 1, true) then
			return
		end

		dir = vim.fs.normalize(dir)
		if not seen[dir] and vim.uv.fs_stat(dir .. "/compile_commands.json") then
			seen[dir] = true
			table.insert(dirs, dir)
		end
	end

	local ok, cmake = pcall(require, "cmake-tools")
	if ok and cmake.is_cmake_project() then
		local selected = cmake.get_build_directory()
		add(selected and (selected.filename or tostring(selected)))
	end

	local root = project_root(source)
	if root then
		local found = {}
		for name, kind in vim.fs.dir(root) do
			if kind == "directory" and name:match("^build") then
				local path = root .. "/" .. name
				local stat = vim.uv.fs_stat(path .. "/compile_commands.json")
				if stat then
					table.insert(found, { path = path, mtime = stat.mtime.sec })
				end
			end
		end
		-- Newest first, so a stale tree does not shadow the one being worked in.
		table.sort(found, function(a, b)
			return a.mtime > b.mtime
		end)
		for _, entry in ipairs(found) do
			add(entry.path)
		end
	end

	return dirs
end

-- compile_commands.json records an object file per source, and its path names
-- the target that compiles it: <dir>/CMakeFiles/<target>.dir/<source>.o. That
-- is the only place the source-to-binary mapping is written down.
local compile_commands = {}

local function source_map(build_dir)
	local path = build_dir .. "/compile_commands.json"
	local stat = vim.uv.fs_stat(path)

	if not stat then
		return nil
	end

	local cached = compile_commands[path]
	if cached and cached.mtime == stat.mtime.sec then
		return cached.sources
	end

	local ok, entries = pcall(function()
		local handle = assert(io.open(path, "r"))
		local text = handle:read("*a")
		handle:close()
		return vim.json.decode(text)
	end)
	if not ok or type(entries) ~= "table" then
		return nil
	end

	local sources = {}
	for _, entry in ipairs(entries) do
		if entry.file and entry.output then
			local prefix, target = entry.output:match("^(.*)CMakeFiles/([^/]+)%.dir/")
			if target then
				sources[vim.fs.normalize(entry.file)] = { target = target, prefix = prefix }
			end
		end
	end

	compile_commands[path] = { mtime = stat.mtime.sec, sources = sources }
	return sources
end

---Locate the built test binary that compiles a source file.
---@param source string
---@return string? executable, string? error
local function test_binary(source)
	local candidates = candidate_build_dirs(source)

	if #candidates == 0 then
		return nil, "no configured build directory with a compile_commands.json was found"
	end

	local tried = {}

	for _, build_dir in ipairs(candidates) do
		local sources = source_map(build_dir)
		local entry = sources and sources[vim.fs.normalize(source)]

		if entry then
			local exe = entry.prefix:sub(1, 1) == "/" and (entry.prefix .. entry.target)
				or (build_dir .. "/" .. entry.prefix .. entry.target)
			exe = vim.fs.normalize(exe)

			if vim.uv.fs_access(exe, "X") then
				return exe
			end
			table.insert(tried, entry.target .. " not built in " .. build_dir)
		else
			table.insert(tried, vim.fs.basename(source) .. " not in " .. build_dir)
		end
	end

	return nil, "no built test binary for " .. vim.fs.basename(source) .. ":\n  " .. table.concat(tried, "\n  ")
end

-- Catch2 separates test specs with commas, so a comma inside a name has to be
-- escaped, as do the wildcard and tag characters.
local function escape_spec(name)
	return (name:gsub("[\\,%[%]%*]", "\\%0"))
end

local function selected_names(tree)
	local names = {}
	local position = tree:data()

	if position.type == "test" then
		return { position.name }
	end

	for _, node in tree:iter() do
		if node.type == "test" then
			table.insert(names, node.name)
		end
	end

	return names
end

function M.root(dir)
	local marker = vim.fs.find({ "CMakePresets.json", ".git" }, { path = dir, upward = true })[1]
	return marker and vim.fs.dirname(marker) or nil
end

function M.filter_dir(name)
	return not (vim.startswith(name, "build") or name == "venv" or name == ".venv")
end

function M.is_test_file(file_path)
	local name, extension = file_path:match("([^/]+)%.([^.]+)$")

	if not name or not vim.tbl_contains({ "cc", "cpp", "cxx" }, extension) then
		return false
	end

	return vim.startswith(name, "test_") or vim.endswith(name, "_test")
end

function M.discover_positions(path)
	-- Reuse neotest-ctest's treesitter query for TEST_CASE/SCENARIO/namespaces.
	local framework = require("neotest-ctest.framework").detect(path)

	if not framework then
		return nil
	end

	return framework.parse_positions(path)
end

---@param args neotest.RunArgs
function M.build_spec(args)
	local tree = args and args.tree

	if not tree then
		return
	end

	local position = tree:data()
	if not vim.tbl_contains({ "test", "namespace", "file" }, position.type) then
		return
	end

	local exe, err = test_binary(position.path)
	if not exe then
		vim.notify("ats-catch2: " .. err, vim.log.levels.ERROR)
		return
	end

	local names = selected_names(tree)
	if #names == 0 then
		return
	end

	local filter = table.concat(vim.tbl_map(escape_spec, names), ",")
	-- nio's variant is safe inside neotest's async context, where vim.fn is not.
	local junit = require("nio").fn.tempname()

	-- The console reporter keeps neotest's output pane useful; the JUnit
	-- reporter is what results() reads. Catch2 accepts both at once.
	local catch2_args = vim.deepcopy(CATCH2_ARGS)
	vim.list_extend(catch2_args, {
		filter,
		"--reporter",
		"junit::out=" .. junit,
		"--reporter",
		"console::out=-",
	})

	local command = { exe }
	vim.list_extend(command, catch2_args)

	-- ctest runs these with the binary's own build directory as cwd.
	local cwd = vim.fs.dirname(exe)
	local spec = { command = command, cwd = cwd, context = { junit = junit } }

	if args.strategy == "dap" then
		spec.strategy = {
			type = "lldb",
			request = "launch",
			name = "Debug " .. names[1],
			program = exe,
			args = catch2_args,
			cwd = cwd,
			stopOnEntry = false,
		}
	end

	return spec
end

---Group JUnit testcases by their TEST_CASE, which owns any SECTION results
---reported beneath it as "TEST_CASE/section name".
local function parse_junit(path)
	local lib = require("neotest.lib")

	if not path or not vim.uv.fs_stat(path) then
		return nil
	end

	local ok, parsed = pcall(function()
		return lib.xml.parse(lib.files.read(path))
	end)
	if not ok then
		return nil
	end

	local suite = parsed and parsed.testsuites and parsed.testsuites.testsuite
	local cases = suite and suite.testcase

	if not cases then
		return {}
	end
	if cases._attr then
		cases = { cases }
	end

	local grouped = {}
	for _, case in ipairs(cases) do
		local name = case._attr and case._attr.name
		if name then
			local base = name:match("^([^/]+)") or name
			local group = grouped[base] or { failures = {} }

			for _, key in ipairs({ "failure", "error" }) do
				local failures = case[key]
				if failures then
					if failures._attr or type(failures) == "string" then
						failures = { failures }
					end
					for _, failure in ipairs(failures) do
						table.insert(group.failures, failure)
					end
				end
			end

			grouped[base] = group
		end
	end

	return grouped
end

local function failure_errors(failures)
	local errors = {}

	for _, failure in ipairs(failures) do
		local text = type(failure) == "table" and (failure[1] or "") or tostring(failure)
		local message = type(failure) == "table" and failure._attr and failure._attr.message or nil
		local line = tostring(text):match("at [^\n]-:(%d+)%s*$")

		table.insert(errors, {
			message = message or vim.trim(tostring(text)),
			-- neotest expects 0-indexed lines.
			line = line and (tonumber(line) - 1) or nil,
		})
	end

	return errors
end

local function collect(tree, cases, output, results)
	local position = tree:data()

	if position.type == "test" then
		local case = cases[position.name]

		if not case then
			results[position.id] = { status = "skipped", output = output }
		elseif #case.failures > 0 then
			local errors = failure_errors(case.failures)
			results[position.id] = {
				status = "failed",
				short = errors[1] and errors[1].message or nil,
				output = output,
				errors = errors,
			}
		else
			results[position.id] = { status = "passed", output = output }
		end

		return results[position.id].status
	end

	local passed, failed = 0, 0
	for _, child in ipairs(tree:children()) do
		local status = collect(child, cases, output, results)
		if status == "passed" then
			passed = passed + 1
		elseif status == "failed" then
			failed = failed + 1
		end
	end

	local status = failed > 0 and "failed" or passed > 0 and "passed" or "skipped"
	results[position.id] = { status = status, output = output }
	return status
end

function M.results(spec, result, tree)
	local cases = parse_junit(spec.context and spec.context.junit)

	if not cases then
		vim.notify("ats-catch2: no JUnit output; see the run output for why", vim.log.levels.WARN)
		return {}
	end

	local results = {}
	collect(tree, cases, result and result.output or nil, results)
	return results
end

---@return neotest.Adapter
function M.adapter()
	return {
		name = "ats-catch2",
		root = M.root,
		filter_dir = M.filter_dir,
		is_test_file = M.is_test_file,
		discover_positions = M.discover_positions,
		build_spec = M.build_spec,
		results = M.results,
	}
end

return M
