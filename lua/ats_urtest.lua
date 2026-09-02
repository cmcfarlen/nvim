-- neotest-python configured for Apache Traffic Server Uranium tests.
--
-- Uranium's pytest plugin needs four runtime paths, a plugin import, and a
-- PYTHONPATH covering the test support packages. All of it is already baked
-- into the CMake-generated <build>/tests/urtest.sh, so read it from there
-- instead of duplicating the paths here.

local M = {}

local ENV_PREFIX = "/usr/bin/env"

-- Cleared so a VPN or corporate proxy cannot intercept test traffic, matching
-- what tools/uranium/runner.py does.
local PROXY_VARIABLES = {
	"HTTP_PROXY",
	"HTTPS_PROXY",
	"NO_PROXY",
	"http_proxy",
	"https_proxy",
	"no_proxy",
}

---Read the --key=value pairs baked into a generated urtest.sh wrapper.
---@param path string
---@return table<string, string>|nil
local function read_wrapper(path)
	local handle = io.open(path, "r")
	if not handle then
		return nil
	end
	local text = handle:read("*a")
	handle:close()

	local values = {}
	for key, value in text:gmatch('%-%-([%a%-]+)=([^"\n]+)') do
		values[key] = value
	end
	return values
end

---Find a configured build that is usable from this host.
---
---A build configured inside a container bind-mounts the tree at its real path,
---so its recorded source root is indistinguishable from a native build's. What
---does distinguish it is that its venv interpreter and proxy-verifier binaries
---are built for the container's platform, not this one.
---@param repo string Repository root.
---@return table<string, string>|nil
local function find_native_build(repo)
	local platform = vim.uv.os_uname().sysname == "Darwin" and "darwin-" or "linux-"
	for _, wrapper in ipairs(vim.fn.glob(repo .. "/build*/tests/urtest.sh", false, true)) do
		local values = read_wrapper(wrapper)
		local interpreter = values and (values["project-directory"] or "") .. "/.venv/bin/python"
		if
			values
			and values["source-root"] == repo
			and values["verifier-bin"]
			and values["verifier-bin"]:find(platform, 1, true)
			and vim.fn.executable(interpreter) == 1
		then
			return values
		end
	end
	return nil
end

local resolved_by_repo = {}
local last_repo = nil

---Resolve the interpreter command and pytest arguments for one repository.
---@param root string neotest root, which is the repository's tests directory.
---@return table|nil
function M.resolve(root)
	local repo = vim.fs.dirname(root)
	last_repo = repo
	if resolved_by_repo[repo] ~= nil then
		return resolved_by_repo[repo] or nil
	end

	local values = find_native_build(repo)
	if not values then
		resolved_by_repo[repo] = false
		vim.notify(
			"ats_urtest: no native urtest build found under " .. repo .. "/build*; "
				.. "configure one with: cmake --preset urtest -B build-urtest-mac",
			vim.log.levels.WARN
		)
		return nil
	end

	local tests = repo .. "/tests"
	local venv = values["project-directory"] .. "/.venv"
	local python = {
		ENV_PREFIX,
		-- Helper processes are console scripts in the venv, and Uranium execs
		-- them by bare name. uv run supplies this; a direct interpreter does not.
		"PATH=" .. venv .. "/bin:" .. (vim.env.PATH or ""),
		"PYTHONPATH=" .. table.concat({
			tests,
			tests .. "/uranium_tests/remap",
			tests .. "/uranium_tests/remap_yaml",
			tests .. "/uranium_tests/lib",
		}, ":"),
		-- dyld ignores LD_LIBRARY_PATH, which is what runner.py sets on Linux.
		"DYLD_LIBRARY_PATH=" .. values["install-prefix"] .. "/lib",
	}
	for _, name in ipairs(PROXY_VARIABLES) do
		table.insert(python, name .. "=")
	end
	table.insert(python, venv .. "/bin/python")

	local resolved = {
		repo = repo,
		python = python,
		args = {
			"-p",
			"tools.uranium.plugin",
			"--import-mode=importlib",
			"--ats-bin=" .. values["install-prefix"] .. "/bin",
			"--proxy-verifier-bin=" .. values["verifier-bin"],
			"--build-root=" .. values["build-root"],
			"--sandbox=" .. values["sandbox"],
		},
	}
	resolved_by_repo[repo] = resolved
	return resolved
end

---Forget cached resolutions so a reconfigured build is picked up.
function M.reload()
	resolved_by_repo = {}
end

---Build the neotest-python adapter for Uranium tests.
---@return table
function M.adapter()
	return require("neotest-python")({
		runner = "pytest",
		python = function(root)
			local resolved = M.resolve(root)
			return resolved and resolved.python or { "python3" }
		end,
		-- neotest-python does not pass root here, so reuse the repository the
		-- python callback resolved for this run.
		args = function(runner, _, _)
			if runner ~= "pytest" then
				return {}
			end
			local resolved = last_repo and resolved_by_repo[last_repo]
			return resolved and vim.deepcopy(resolved.args) or {}
		end,
	})
end

return M
