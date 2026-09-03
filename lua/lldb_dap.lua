-- Locating lldb-dap, which differs by how Swift was installed:
--
--   Xcode    not on PATH at all, has to come from xcrun, and only the
--            Swift-enabled build there can debug Swift
--   distro   alongside swift, e.g. /usr/bin/lldb-dap
--   swiftly  inside the managed toolchain. Its PATH entries are proxy binaries
--            rather than symlinks, so resolving `swift` does not lead there; ask
--            the compiler where its resources are instead.

local M = {}

---@return string? path
function M.find()
	local on_path = vim.fn.exepath("lldb-dap")
	if on_path ~= "" then
		return on_path
	end

	if vim.fn.has("mac") == 1 then
		local found = vim.system({ "xcrun", "-f", "lldb-dap" }, { text = true }):wait()
		local path = vim.trim(found.stdout or "")
		if path ~= "" then
			return path
		end
	end

	local info = vim.system({ "swift", "-print-target-info" }, { text = true }):wait()
	local ok, decoded = pcall(vim.json.decode, info.stdout or "")
	local resources = ok and decoded and decoded.paths and decoded.paths.runtimeResourcePath

	if resources then
		-- <toolchain>/usr/lib/swift -> <toolchain>/usr/bin/lldb-dap
		local candidate = vim.fs.dirname(vim.fs.dirname(resources)) .. "/bin/lldb-dap"
		if vim.uv.fs_access(candidate, "X") then
			return candidate
		end
	end

	return nil
end

return M
