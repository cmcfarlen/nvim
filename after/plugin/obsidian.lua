
require("obsidian").setup({
  dir = "~/Documents/projects",
  notes_subdir = "notes",
  daily_notes = {
    folder = "notes/journal",
    date_format = "%Y-%m-%d",
  },
  completion = {
    new_notes_location = "notes_subdir",
  },
})
