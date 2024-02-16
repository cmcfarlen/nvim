
vim.opt_local.conceallevel = 2

local obsidian = require("obsidian")
local client = obsidian.setup({
  workspaces = {
    {
      name = "apple",
      path = "~/vaults/apple",
    },
    {
      name = "personal",
      path = "~/vaults/personal",
    },
  },
  daily_notes = {
    folder = "notes/journal",
    date_format = "%Y-%m-%d",
  },
  completion = {
    nvim_cmp = true,
    min_chars = 2,
  },
  mappings = {
    -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
    ["gf"] = {
      action = function()
        return require("obsidian").util.gf_passthrough()
      end,
      opts = { noremap = false, expr = true, buffer = true },
    },
    -- Toggle check-boxes.
    ["<leader>ch"] = {
      action = function()
        return require("obsidian").util.toggle_checkbox()
      end,
      opts = { buffer = true },
    },
    -- custom
    ["<leader>ot"] = {
      action = function()
        return require("obsidian").util.today()
      end,
      opts = { buffer = true },
    },
    ["<leader>oy"] = {
      action = function()
        return require("obsidian").util.yesterday()
      end,
      opts = { buffer = true },
    },
    ["<leader>os"] = {
      action = function()
        return require("obsidian").util.search()
      end,
      opts = { buffer = true },
    },
    ["<leader>ob"] = {
      action = function()
        return require("obsidian").util.backlinks()
      end,
      opts = { buffer = true },
    },
  },

})


-- vim.opt.conceallevel = 1
-- local obsidian = require("obsidian")
-- local client = obsidian.setup({
--   dir = "~/Documents/projects",
--   notes_subdir = "notes",
--   daily_notes = {
--     folder = "notes/journal",
--     date_format = "%Y-%m-%d",
--   },
--   note_id_func = function(title)
--     return title
--   end,
-- })
-- 
-- local function c(cmd)
--   return function()
--     cmd(client)
--   end
-- end
-- 
-- local command = require("obsidian.command")
-- vim.keymap.set("n", "<leader>ot", c(command.today), {})
-- vim.keymap.set("n", "<leader>oy", c(command.yesterday), {})
-- vim.keymap.set("n", "<leader>os", c(command.search), {})
-- vim.keymap.set("n", "<leader>ob", c(command.backlinks), {})
-- 
-- 
-- vim.api.nvim_create_autocmd(
--   {"BufRead", "BufNewFile"},
--   { pattern = { "*.md", "*.txt" },
--     callback = function()
--       print("autocmd callback")
--       vim.api.nvim_command('setlocal wrap')
--       vim.api.nvim_command('setlocal spell spelllang=en_us')
--     end}
-- 
-- )

