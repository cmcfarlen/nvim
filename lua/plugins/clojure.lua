-- Clojure-specific setup, layered on top of the LazyVim `lang.clojure` extra.
--
-- The extra already provides: conjure, nvim-paredit, treesitter, baleia
-- (colorized eval log), and remaps K -> <localleader>K, gd -> <localleader>gd
-- so plain K/gd stay with clojure-lsp.
--
-- This file adds what the extra leaves out.
return {
	-- 1. Rainbow parens.
	--    The old p00f/nvim-ts-rainbow and its successor nvim-ts-rainbow2 are
	--    both archived. rainbow-delimiters.nvim is the maintained one, and it
	--    is treesitter-based, so it colors actual forms rather than guessing
	--    with regex.
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = "LazyFile",
		config = function()
			local rd = require("rainbow-delimiters")
			vim.g.rainbow_delimiters = {
				strategy = {
					[""] = rd.strategy["global"],
					-- Local strategy only highlights the form under the cursor, which
					-- is much less noisy in deeply nested Clojure.
					clojure = rd.strategy["local"],
				},
				query = {
					[""] = "rainbow-delimiters",
					clojure = "rainbow-delimiters",
				},
				highlight = {
					"RainbowDelimiterYellow",
					"RainbowDelimiterViolet",
					"RainbowDelimiterBlue",
					"RainbowDelimiterOrange",
					"RainbowDelimiterGreen",
					"RainbowDelimiterCyan",
					"RainbowDelimiterRed",
				},
			}
		end,
	},

	-- 2. clojure-lsp. The extra installs no LSP server at all, which is why
	--    go-to-definition did nothing: conjure was attached (hence eval worked)
	--    but nothing was answering LSP requests.
	--
	--    NOTE: do not add an `init` here. LazyVim's own nvim-lspconfig spec has
	--    one, and lazy.nvim keeps only a single `init` per plugin -- adding one
	--    silently replaces theirs. Reading definitions out of jars therefore
	--    lives in `lua/config/autocmds.lua`.
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				clojure_lsp = {
					-- Roots: without deps.edn/project.clj present, clojure-lsp attaches
					-- to the wrong directory and finds no sources to index.
					root_markers = { "deps.edn", "project.clj", "bb.edn", "shadow-cljs.edn", ".git" },
				},
			},
		},
	},

	-- 3. REPL-aware completion on blink.cmp.
	--    The LazyVim extra wires cmp-conjure, but that block is nvim-cmp-only
	--    and is silently skipped on blink.cmp -- so completion from the live
	--    REPL is missing by default.
	--
	--    No external plugin is needed: Conjure sets
	--    `vim.bo.omnifunc = "v:lua._conjure_omnifunc"` in Clojure buffers, and
	--    blink.cmp ships an `omni` provider that wraps whatever omnifunc is
	--    set. Its built-in `enabled` check fires precisely when omnifunc is
	--    not the LSP default, so it activates for Conjure buffers only.
	--
	--    This means completion candidates come from the *running program*, not
	--    just static analysis -- so runtime-defined vars complete too.
	{
		"saghen/blink.cmp",
		optional = true,
		-- NOTE: opts must be a function here. LazyVim *concatenates* list-valued
		-- opts, so declaring `sources.default = {...}` appends to the existing
		-- defaults and yields duplicates. Append the one source we need instead.
		opts = function(_, opts)
			opts.sources = opts.sources or {}
			opts.sources.default = opts.sources.default or {}
			if not vim.tbl_contains(opts.sources.default, "omni") then
				table.insert(opts.sources.default, "omni")
			end
			opts.sources.providers = opts.sources.providers or {}
			-- Rank REPL results above buffer text but below LSP.
			opts.sources.providers.omni =
				vim.tbl_deep_extend("force", opts.sources.providers.omni or {}, { score_offset = 5 })
			return opts
		end,
	},

	-- 4. Conjure tweaks the extra does not set.
	{
		"Olical/conjure",
		init = function()
			-- Show eval results inline as virtual text, not only in the log buffer.
			vim.g["conjure#eval#result_register"] = "c"
			vim.g["conjure#highlight#enabled"] = true
			-- The HUD covers the buffer on every eval; the log split is calmer.
			vim.g["conjure#log#hud#enabled"] = false
			vim.g["conjure#log#wrap"] = true
			-- Auto-require the ns on connect so `gd` and eval agree on context.
			vim.g["conjure#client#clojure#nrepl#eval#auto_require"] = true
			-- Use clj-kondo/LSP for linting; conjure need not duplicate it.
			vim.g["conjure#client#clojure#nrepl#test#runner"] = "clojure"
		end,
	},
}
