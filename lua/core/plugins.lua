local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
	use 'wbthomason/packer.nvim'

	use {
		'nvim-telescope/telescope.nvim', branch = '0.1.x',
		requires = { {'nvim-lua/plenary.nvim'} }
	}

	use 'Mofiqul/dracula.nvim'

	use ('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
	use 'nvim-treesitter/playground'
	use 'mbbill/undotree'
	use 'tpope/vim-fugitive'
  use 'tpope/vim-surround'
  use 'cohama/lexima.vim'

  use 'mfussenegger/nvim-dap'

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'saadparwaiz1/cmp_luasnip'
  use 'hrsh7th/cmp-nvim-lua'
  use 'L3MON4D3/LuaSnip'

  use 'neovim/nvim-lspconfig'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'

  use 'ilyachur/cmake4vim'

	if packer_bootstrap then
		require('packer').sync()
	end
end)
