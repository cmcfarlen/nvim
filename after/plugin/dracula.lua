vim.cmd.colorscheme('dracula')

-- This is temp until dracula support LspInlayHint
vim.api.nvim_set_hl(0, 'LspInlayHint', {
  italic = true,
  bg = vim.g['dracula#palette'].bglight[1],
  fg = vim.g['dracula#palette'].comment[1], --228,
})



