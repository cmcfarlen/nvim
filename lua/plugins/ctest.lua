---@diagnostic disable: missing-fields
---
local function plog()
	local niolog = require("nio.logger").new("wtf", { level = vim.log.levels.DEBUG })

	niolog.warn("Got em")
	return niolog
end

-- Helper function to find project root
local function find_project_root(file_path)
	local logger = require("neotest.logging")
	-- Debug: show what file we're checking
	plog().warn("Finding root for: " .. file_path)

	-- Look for CMakeLists.txt, CMakePresets.json, or .git
	local root = vim.fs.find({ "CMakePresets.json", ".git" }, {
		path = file_path,
		upward = true,
		type = "file", -- or "directory" for .git
	})[1]

	if root then
		-- Get the directory containing the root marker
		local root_dir = vim.fs.dirname(root)
		plog().warn("Found root: " .. root_dir)
		return root_dir
	end

	-- Fallback to current working directory
	local fallback = vim.fn.getcwd()
	plog().warn("No root found, using cwd: " .. fallback)
	return fallback
end

local function my_filter_dir(name, rel_path, root)
	local neotest_config = require("neotest.config")
	local fn = vim.tbl_get(neotest_config, "projects", root, "discovery", "filter_dir")
	if fn ~= nil then
		return fn(name, rel_path, root)
	end

	local dir_filters = {
		["build"] = false,
		["build-mydev"] = false,
		["build-mydev-asan"] = false,
		["tests"] = false,
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

return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		-- Other neotest dependencies here
		"orjangj/neotest-ctest",
	},
	config = function()
		local lib = require("neotest.lib")
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

		require("neotest").setup({
			log_level = vim.log.levels.DEBUG,
			adapters = {
				-- Load with default config
				require("neotest-ctest").setup({

					is_test_file = function(file_path)
						plog().warn("Checking file: " .. file_path)
						local elems = vim.split(file_path, lib.files.sep, { plain = true })
						local name, extension = unpack(vim.split(elems[#elems], ".", { plain = true }))
						local supported_extensions = { "cpp", "cc", "cxx" }
						return vim.tbl_contains(supported_extensions, extension)
								and (vim.startswith(name, "test_") or vim.endswith(name, "_test"))
							or false
					end,
					-- Explicitly set the root directory
					root = function(file_path)
						plog().warn("Checking root dir: " .. file_path)
						return find_project_root(file_path)
					end,
					-- Framework
					frameworks = { "catch2" },
					-- Use the build directory from CMakePresets
					build_directory = "build-mydev",
					-- Framework
					-- Enable verbose output for debugging
					extra_args = { "--verbose" },
				}),
			},
			projects = {
				["~/projects/oss/trafficserver"] = {
					discovery = {
						enabled = false,
						concurrent = 1,
						filter_dir = my_filter_dir,
					},
					adapters = {
						require("neotest-ctest").setup({
							build_directory = "build-mydev",
							frameworks = { "catch2" },
							is_test_file = function(file_path)
								local elems = vim.split(file_path, lib.files.sep, { plain = true })
								local name, extension = unpack(vim.split(elems[#elems], ".", { plain = true }))
								local supported_extensions = { "cpp", "cc", "cxx" }
								return vim.tbl_contains(supported_extensions, extension)
										and (vim.startswith(name, "test_") or vim.endswith(name, "_test"))
									or false
							end,
						}),
					},
				},
			},
		})
	end,
}
