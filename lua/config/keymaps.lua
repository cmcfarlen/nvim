vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

local tmux = require("tmux")
vim.keymap.set("n", "<C-h>", tmux.move_left, { silent = true, desc = "Tmux move left" })
vim.keymap.set("n", "<C-j>", tmux.move_bottom, { silent = true, desc = "Tmux move bottom" })
vim.keymap.set("n", "<C-k>", tmux.move_top, { silent = true, desc = "Tmux move top" })
vim.keymap.set("n", "<C-l>", tmux.move_right, { silent = true, desc = "Tmux move right" })
vim.keymap.set(
	"n",
	"<Leader>gl",
	"<cmd>Gitsigns toggle_current_line_blame<cr>",
	{ silent = true, desc = "Toggle blame lines" }
)

vim.keymap.del({ "n", "i", "v" }, "<M-j>")
vim.keymap.del({ "n", "i", "v" }, "<M-k>")
