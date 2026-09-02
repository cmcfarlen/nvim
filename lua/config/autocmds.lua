-- Loaded automatically by LazyVim after its own autocmds.
-- Keep user autocmds here rather than in a plugin spec's `init`: when two
-- specs target the same plugin, lazy.nvim keeps only one `init` function, so
-- adding one to the nvim-lspconfig spec silently replaced LazyVim's.

-- ---------------------------------------------------------------------------
-- Read Clojure (and Java) definitions that live inside jars.
--
-- Go-to-definition on a clojure.core symbol returns a URI like
--   zipfile:///~/.m2/.../clojure-1.12.0.jar::clojure/core.clj
-- Neovim cannot read that, so the buffer opens EMPTY: the built-in zipPlugin
-- claims `BufReadCmd zipfile:*` but does not understand the `::` inner-path
-- separator clojure-lsp uses, and nothing else knows the scheme.
--
-- clojure-lsp does expose a `clojure/dependencyContents` request, but it
-- routes through the java-interop feature (for decompiling .class files) and
-- returns an Internal error for .clj entries -- verified. Reading the zip
-- entry directly is simpler and works for any jar.
local group = vim.api.nvim_create_augroup("JarFileContents", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadCmd", "FileReadCmd" }, {
	group = group,
	-- A pattern with no `/` matches only the filename tail, which is why
	-- zipPlugin registers both forms. Filter precisely in the callback.
	pattern = { "zipfile:*", "zipfile:*/*", "jar:*", "jar:*/*" },
	-- Do NOT `return true` here: a truthy return *deletes the autocmd*, it
	-- does not mean "handled".
	callback = function(ev)
		local uri = ev.match

		-- zipfile:///path/to.jar::inner/path  |  jar:file:///path.jar!/inner
		local jar, inner = uri:match("^zipfile://(.+)::(.+)$")
		if not jar then
			jar, inner = uri:match("^jar:file://(.+)!/(.+)$")
		end
		if not jar then
			return
		end

		jar = vim.uri_decode(jar)
		inner = vim.uri_decode(inner)

		local res = vim.system({ "unzip", "-p", jar, inner }, { text = true }):wait()
		if res.code ~= 0 or not res.stdout or res.stdout == "" then
			vim.notify(("could not read %s from %s"):format(inner, jar), vim.log.levels.WARN)
			return
		end

		local lines = vim.split(res.stdout, "\n", { plain = true })
		if lines[#lines] == "" then
			table.remove(lines)
		end

		vim.bo[ev.buf].modifiable = true
		vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, lines)
		vim.bo[ev.buf].filetype = vim.filetype.match({ filename = inner }) or "clojure"
		-- Library source is read-only; unmodified keeps :q quiet.
		vim.bo[ev.buf].modifiable = false
		vim.bo[ev.buf].modified = false
		vim.bo[ev.buf].readonly = true
		vim.bo[ev.buf].swapfile = false
	end,
})
