

local tabs = 2

vim.opt.shiftwidth = tabs
vim.opt.softtabstop = tabs
vim.opt.tabstop = tabs
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. ".cache/nvim/undodir"
vim.opt.undofile = true

vim.opt.termguicolors = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.updatetime = 50


