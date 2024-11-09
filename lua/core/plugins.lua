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
  use {
      'stevearc/overseer.nvim',
      config = function() require('overseer').setup() end
  }
  use 'nvim-telescope/telescope-ui-select.nvim'

	use 'dracula/vim'

	use ('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
  use {
    "nvim-treesitter/nvim-treesitter-textobjects",
    after = "nvim-treesitter",
    requires = "nvim-treesitter/nvim-treesitter",
  }
	use 'nvim-treesitter/playground'
	use 'nvim-treesitter/nvim-treesitter-context'
  use "lukas-reineke/indent-blankline.nvim"  -- optional
  use "kiyoon/treesitter-indent-object.nvim"
	use 'mbbill/undotree'
	use 'tpope/vim-fugitive'
  use 'tpope/vim-surround'
  use 'tpope/vim-repeat'
  use 'cohama/lexima.vim'

  use 'mfussenegger/nvim-dap'

  use { "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"} }

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

  use 'unblevable/quick-scope'
  use 'Civitasv/cmake-tools.nvim'

  use "aserowy/tmux.nvim"
  use {
    "nvim-neotest/neotest",
    requires = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "vim-test/vim-test",
      "orjangj/neotest-ctest",
    }
  }

  use "b0o/schemastore.nvim"

	use({
		"epwalsh/obsidian.nvim",
		requires = {
			-- Required.
			"nvim-lua/plenary.nvim",

			-- see below for full list of optional dependencies 👇
		},
	})

  use 'dstein64/vim-startuptime'

  -- install without yarn or npm
  use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
  })

  use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function()
    vim.g.mkdp_filetypes = { "markdown" }
    vim.g.mkdp_preview_options = {
      uml = { server = "http://localhost:8280" },
    }
  end, ft = { "markdown" }, })

	if packer_bootstrap then
		require('packer').sync()
	end
end)
