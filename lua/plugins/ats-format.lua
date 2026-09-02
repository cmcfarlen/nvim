-- Format Python with the repository's own pinned yapf, so format-on-save agrees
-- with the `format` CMake target.
--
-- LazyVim otherwise formats Python through the ruff LSP, which is black-style
-- at 88 columns. Apache Traffic Server uses yapf with .style.yapf at 132
-- columns, so the two fight over every file.
--
-- tools/yapf.sh pins the version and rejects any other, so read the pin from
-- there instead of duplicating it. Both the style file and the version are
-- discovered from the buffer, so this stays inert outside such a repository.

local DEFAULT_VERSION = "0.43.0"

local style_by_dir = {}
local version_by_root = {}

---Locate .style.yapf above a buffer, if any.
---@param bufnr integer
---@return string|nil Absolute path to the style file.
local function find_style(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return nil
	end
	local dir = vim.fs.dirname(name)
	if style_by_dir[dir] == nil then
		style_by_dir[dir] = vim.fs.find(".style.yapf", { path = dir, upward = true, type = "file" })[1] or false
	end
	return style_by_dir[dir] or nil
end

---Read the yapf version pinned by tools/yapf.sh next to a style file.
---@param style string Absolute path to .style.yapf.
---@return string
local function pinned_version(style)
	local root = vim.fs.dirname(style)
	if version_by_root[root] == nil then
		version_by_root[root] = false
		local script = io.open(root .. "/tools/yapf.sh", "r")
		if script then
			local text = script:read("*a")
			script:close()
			version_by_root[root] = text:match('YAPF_VERSION="([^"]+)"') or false
		end
	end
	return version_by_root[root] or DEFAULT_VERSION
end

---Forget cached lookups after a branch switch changes the pin.
local function reload()
	style_by_dir = {}
	version_by_root = {}
end

return {
	"stevearc/conform.nvim",
	optional = true,
	opts = function(_, opts)
		vim.api.nvim_create_user_command("AtsYapfReload", reload, { desc = "Reset cached .style.yapf lookups" })

		opts.formatters = opts.formatters or {}
		opts.formatters.ats_yapf = {
			command = "uv",
			args = function(_, ctx)
				local style = find_style(ctx.buf)
				return {
					"tool",
					"run",
					"--quiet",
					"yapf@" .. pinned_version(style),
					"--style",
					style,
				}
			end,
			-- yapf reads stdin only when given no filename; "-" is rejected.
			stdin = true,
			cwd = function(_, ctx)
				return vim.fs.dirname(find_style(ctx.buf))
			end,
			condition = function(_, ctx)
				return find_style(ctx.buf) ~= nil
			end,
		}

		opts.formatters_by_ft = opts.formatters_by_ft or {}
		-- A function so buffers outside such a repository report no conform
		-- source at all, letting LazyVim fall back to the ruff LSP as before.
		opts.formatters_by_ft.python = function(bufnr)
			return find_style(bufnr) and { "ats_yapf" } or {}
		end
	end,
}
