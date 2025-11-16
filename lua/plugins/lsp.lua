return {
  'neovim/nvim-lspconfig',

  dependencies = {
    { 'mason-org/mason.nvim', config = true },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    {
      'j-hui/fidget.nvim',
      opts = {
        notification = {
          window = {
            winblend = 0,
          },
        },
      },
    },

    'hrsh7th/cmp-nvim-lsp',
  },

  config = function()
    -------------------------------------------------------------------------
    -- Inline diagnostics (important: virtual_text must be enabled)
    -------------------------------------------------------------------------
    vim.diagnostic.config {
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = false,
    }

    -------------------------------------------------------------------------
    -- LspAttach: Keybinds & features per buffer
    -------------------------------------------------------------------------
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),

      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        -- Highlight references
        if client and client:supports_method('textDocument/documentHighlight') then
          local group = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })

          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = group,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = group,
            callback = vim.lsp.buf.clear_references,
          })
        end

        -- Inlay hints
        if client and client:supports_method('textDocument/inlayHint') then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(
              not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }
            )
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -------------------------------------------------------------------------
    -- Capabilities with nvim-cmp
    -------------------------------------------------------------------------
    local capabilities = vim.tbl_deep_extend(
      'force',
      vim.lsp.protocol.make_client_capabilities(),
      require('cmp_nvim_lsp').default_capabilities()
    )

    -------------------------------------------------------------------------
    -- LSP server configurations
    -------------------------------------------------------------------------
    local servers = {
      ts_ls = {},
      ruff = {},
      pylsp = {
        settings = {
          pylsp = {
            plugins = {
              pyflakes = { enabled = false },
              pycodestyle = { enabled = false },
              autopep8 = { enabled = false },
              yapf = { enabled = false },
              mccabe = { enabled = false },
              pylsp_mypy = { enabled = false },
              pylsp_black = { enabled = false },
              pylsp_isort = { enabled = false },
            },
          },
        },
      },

      html = { filetypes = { 'html', 'twig', 'hbs' } },
      cssls = {},
      tailwindcss = {},
      dockerls = {},
      sqlls = {},
      terraformls = {},
      jsonls = {},
      yamlls = {},
      gopls = {
      settings = {
       gopls = {
        analyses = {
         unusedparams = true,
        },
        staticcheck = true,
       },
      },
    },

      -------------------------------------------------------------------
      -- FIXED lua_ls configuration (diagnostics properly placed)
      -------------------------------------------------------------------
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            runtime = { version = 'LuaJIT' },

            workspace = {
              checkThirdParty = false,
              library = {
                '${3rd}/luv/library',
                unpack(vim.api.nvim_get_runtime_file('', true)),
              },
            },

            diagnostics = {
              globals = { 'vim' },
              disable = { 'missing-fields' },
            },

            format = {
              enable = false,
            },
          },
        },
      },
    }

    -------------------------------------------------------------------------
    -- Install all servers
    -------------------------------------------------------------------------
    local ensure = vim.tbl_keys(servers)
    vim.list_extend(ensure, {
      'stylua',
    })

    require('mason-tool-installer').setup {
      ensure_installed = ensure,
    }

    -------------------------------------------------------------------------
    -- Start all LSP servers
    -------------------------------------------------------------------------
    for server, cfg in pairs(servers) do
      cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})

      vim.lsp.config(server, cfg)
      vim.lsp.enable(server)
    end
  end,
}

