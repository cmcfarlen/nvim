---@diagnostic disable: missing-fields
---
-- Helper function to find project root
local function find_project_root(file_path)
	-- Look for CMakeLists.txt, CMakePresets.json, or .git
	local root = vim.fs.find({ "CMakePresets.json", ".git" }, {
		path = file_path,
		upward = true,
		type = "file", -- or "directory" for .git
	})[1]

	if root then
		-- Get the directory containing the root marker
		return vim.fs.dirname(root)
	end

	-- Fallback to current working directory
	return vim.fn.getcwd()
end

local function is_cxx_test_file(file_path)
	local lib = require("neotest.lib")
	local elems = vim.split(file_path, lib.files.sep, { plain = true })
	local name, extension = unpack(vim.split(elems[#elems], ".", { plain = true }))
	local supported_extensions = { "cpp", "cc", "cxx" }

	return vim.tbl_contains(supported_extensions, extension)
			and (vim.startswith(name, "test_") or vim.endswith(name, "_test"))
		or false
end

local function my_filter_dir(name, rel_path, root)
	local neotest_config = require("neotest.config")
	local fn = vim.tbl_get(neotest_config, "projects", root, "discovery", "filter_dir")
	if fn ~= nil then
		return fn(name, rel_path, root)
	end

	-- Any out-of-source build directory, plus virtualenvs, whose site-packages
	-- are full of upstream test_*.py files.
	if vim.startswith(name, "build") or name == "venv" or name == ".venv" then
		return false
	end

	local dir_filters = {
		["cmake"] = false,
		["doc"] = false,
		["docs"] = false,
		["example"] = false,
		["tools"] = false,
		["configs"] = false,
		["contrib"] = false,
		["ci"] = false,
		["dist"] = false,
	}
	return dir_filters[name] == nil
end

-- neotest-ctest picks its --test-dir by scanning the project root for the first
-- CTestTestfile.cmake it happens to find, which is the wrong build tree whenever
-- more than one exists. Start that scan at the build directory cmake-tools has
-- selected instead, so ctest follows the active configure preset.
local function follow_cmake_build_directory()
	local loaded, ctest = pcall(require, "neotest-ctest.ctest")

	if not loaded then
		return
	end

	local new = ctest.new

	ctest.new = function(self, cwd)
		local ok, cmake = pcall(require, "cmake-tools")

		if ok and cmake.is_cmake_project() then
			local dir = cmake.get_build_directory()
			dir = dir and (dir.filename or tostring(dir))
			if dir and vim.uv.fs_stat(dir .. "/CTestTestfile.cmake") then
				return new(self, dir)
			end
		end

		return new(self, cwd)
	end
end

return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		-- Other neotest dependencies here
		"orjangj/neotest-ctest",
		"nvim-neotest/neotest-python",
	},
	config = function()
		-- Optional, but recommended, if you have enabled neotest's diagnostic option
		local neotest_ns = vim.api.nvim_create_namespace("neotest")
		vim.diagnostic.config({
			virtual_text = {
				format = function(diagnostic)
					-- Convert newlines, tabs and whitespaces into a single whitespace
					-- for improved virtual text readability
					local message = diagnostic.message:gsub("[\r\n\t%s]+", " ")
					return message
				end,
			},
		}, neotest_ns)

		follow_cmake_build_directory()

		-- neotest-ctest keeps its config in a module-level table and hands back the
		-- same adapter every time, so setup() can only be called once: a second call
		-- resets every option the first one set. Configure it here and reuse it.
		local ctest_adapter = require("neotest-ctest").setup({
			is_test_file = is_cxx_test_file,
			-- Explicitly set the root directory
			root = find_project_root,
			-- Framework
			frameworks = { "catch2" },
			-- Adapter used by <leader>td to debug the nearest test
			dap_adapter = "lldb",
			-- Enable verbose output for debugging
			extra_args = { "--verbose" },
		})

		local adapters = {
			ctest_adapter,
			require("ats_urtest").adapter(),
		}

		-- Internal GHE plugin, so absent on hosts without access to it. The wrapper
		-- adds the dap strategy it lacks, so <leader>td works on swift tests.
		local swift_adapter = require("swift_test_dap").adapter()
		if swift_adapter then
			table.insert(adapters, swift_adapter)
		end

		require("neotest").setup({
			log_level = vim.log.levels.DEBUG,
			adapters = adapters,
			projects = {
				[vim.fn.expand("~/projects/oss/trafficserver")] = {
					discovery = {
						enabled = false,
						concurrent = 1,
						filter_dir = my_filter_dir,
					},
					adapters = {
						-- ATS registers one CTest test per binary, so CTest cannot name a
						-- single TEST_CASE and neotest-ctest ends up running nothing. This
						-- adapter runs the Catch2 binary directly instead.
						require("ats_catch2").adapter(),
						require("ats_urtest").adapter(),
					},
				},
			},
		})
	end,
}
