return {
  -- Mason Package Manager for LSP/Linters/Formatters,etc.
  -- Disable this if using native packages.
  {
    'williamboman/mason.nvim',
    dependencies = {
      {
        'williamboman/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',
      },
    },
    config = function()
      require('mason').setup()
      require('mason-lspconfig').setup {
        ensure_installed = { 'lua_ls', 'pyright', 'clangd' },
      }
      require('mason-tool-installer').setup {
        ensure_installed = { 'stylua', 'taplo', 'prettierd', 'ruff' },
      }
    end,
  },

  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'j-hui/fidget.nvim', opts = {} },
      {
        'Bilal2453/luvit-meta',
        lazy = true,
      },
      {
        'folke/lazydev.nvim',
        ft = 'lua',
        opts = {
          library = {
            { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
          },
        },
      },
    },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local lsp = require 'lspconfig'

      -- Servers to configure with the same capabilities
      local servers = { 'lua_ls', 'pyright', 'clangd', 'rust_analyzer' }

      for _, server in ipairs(servers) do
        lsp[server].setup { capabilities = capabilities }
      end
    end,
  },
}
