vim.cmd.colorscheme('dracula')


-- This doesn't work
--vim.api.nvim_set_var('qs_highlight_on_keys', {'f','F', 't','T'})
-- vim.g.qa_highlight_on_keys = {'f', 'F', 't', 'T'}

vim.api.nvim_set_hl(0, 'LspInlayHint', {
  italic = true,
  bg = vim.g['dracula#palette'].bglight[1],
  fg = vim.g['dracula#palette'].comment[1], --228,
})

--cterm=italic ctermfg=228 gui=italic guifg=#f1fa8c


