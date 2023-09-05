
local obsidian = require("obsidian")
local client = obsidian.setup({
  dir = "~/Documents/projects",
  notes_subdir = "notes",
  daily_notes = {
    folder = "notes/journal",
    date_format = "%Y-%m-%d",
  },
  completion = {
    new_notes_location = "notes_subdir",
    prepend_note_id = false,
  },
  note_id_func = function(title)
    return title
  end,
})

local function c(cmd)
  return function()
    cmd(client)
  end
end

local command = require("obsidian.command")
vim.keymap.set("n", "<leader>ot", c(command.today), {})
vim.keymap.set("n", "<leader>oy", c(command.yesterday), {})
vim.keymap.set("n", "<leader>os", c(command.search), {})
vim.keymap.set("n", "<leader>ob", c(command.backlinks), {})

