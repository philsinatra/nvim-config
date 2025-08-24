local lspconfig = require('lspconfig')
local cmp = require('cmp')
local luasnip = require('luasnip')

-- Configure diagnostics with suppression for eslint_d in Biome projects
vim.diagnostic.config({
  virtual_text = {
    prefix = '●', -- Customize the prefix for virtual text
    source = 'always', -- Show source (e.g., 'eslint', 'ts_ls')
    format = function(diagnostic)
      -- Suppress eslint_d diagnostics if biome.json exists
      local biome_config_path = vim.fn.getcwd() .. '/biome.json'
      if vim.fn.filereadable(biome_config_path) == 1 and diagnostic.source == 'eslint_d' then
        return nil
      end
      return diagnostic.message
    end,
  },
  float = {
    source = 'always', -- Show source in floating window
    border = 'rounded', -- Add a border to the floating window
    format = function(diagnostic)
      -- Suppress eslint_d diagnostics in float if biome.json exists
      local biome_config_path = vim.fn.getcwd() .. '/biome.json'
      if vim.fn.filereadable(biome_config_path) == 1 and diagnostic.source == 'eslint_d' then
        return nil
      end
      return diagnostic.message
    end,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Ensure mason-lspconfig sets up LSPs
require('mason-lspconfig').setup({
  ensure_installed = { 'cssls', 'html', 'svelte', 'ts_ls', 'eslint', 'emmet_ls', 'intelephense', 'biome' }, 
  automatic_installation = true,
})

-- Configure LSPs with custom settings
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Default setup for cssls
lspconfig.cssls.setup({
  capabilities = capabilities,
})

-- HTML with disabled CSS validation
lspconfig.html.setup({
  capabilities = capabilities,
  settings = {
    html = {
      validate = {
        styles = false, -- Disable CSS validation
      },
    },
  },
})

-- PHP (Intelephense)
lspconfig.intelephense.setup({
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern('composer.json', '.git'),
})

-- Svelte
lspconfig.svelte.setup({
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern('svelte.config.js', 'package.json'),
})

-- TypeScript
lspconfig.ts_ls.setup({
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern('tsconfig.json', 'package.json'),
})

-- ESLint (conditional setup)
local eslint_bin = vim.fn.getcwd() .. '/node_modules/.bin/eslint'
local eslint_config_patterns = { 'eslint.config.js', '.eslintrc', '.eslintrc.js', '.eslintrc.json', '.eslintrc.yaml', '.eslintrc.yml' }
local has_eslint_config = false
for _, pattern in ipairs(eslint_config_patterns) do
  if vim.fn.filereadable(vim.fn.getcwd() .. '/' .. pattern) == 1 then
    has_eslint_config = true
    break
  end
end
if vim.fn.executable(eslint_bin) == 1 and has_eslint_config then
  lspconfig.eslint.setup({
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = bufnr,
        command = 'EslintFixAll',
      })
    end,
    settings = {
      format = { enable = true },
      workingDirectory = { mode = 'auto' },
      codeAction = {
        disableRuleComment = { enable = true, location = 'separateLine' },
        showDocumentation = { enable = true },
      },
    },
    root_dir = lspconfig.util.root_pattern('eslint.config.js', '.eslintrc', '.eslintrc.js', '.eslintrc.json', 'package.json'),
  })
end

-- Conditional Biome setup
local biome_config_path = vim.fn.getcwd() .. '/biome.json'
if vim.fn.filereadable(biome_config_path) == 1 then
  lspconfig.biome.setup({
    capabilities = capabilities,
    root_dir = lspconfig.util.root_pattern('biome.json', 'package.json'),
    on_attach = function(client, bufnr)
      vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
      -- Explicitly enable formatting for Biome
      client.server_capabilities.documentFormattingProvider = true
      -- Format with Biome on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr, filter = function(c) return c.name == 'biome' end })
        end,
      })
      -- Disable formatting for eslint and ts_ls to avoid conflicts with Biome
      local active_clients = vim.lsp.get_clients() or {}
      for _, active_client in ipairs(active_clients) do
        if active_client.name == 'eslint' or active_client.name == 'ts_ls' then
          active_client.server_capabilities.documentFormattingProvider = false
        end
      end
    end,
  })
end

-- Emmet Language Server
lspconfig.emmet_ls.setup({
  capabilities = capabilities,
  filetypes = {
    "html",
    "css",
    "javascriptreact",
    "php",
    "typescriptreact",
    "svelte",
  },
  init_options = {
    html = {
      options = {
          ["tab_stops"] = true
      },
    },
  },
})

require('lspconfig').emmet_language_server.setup({
  filetypes = {
    'css', 'eruby', 'html', 'javascriptreact', 'php', 'scss', 'typescriptreact'
  },
  init_options = {
    preferences = {},
    showExpandedAbbreviations = "always",
    showAbbreviationSuggestions = true,
    showsuggestionAsSnippets = false,
    syntaxProfiles = {},
    variables = {},
    excludedLanguages = {},
  },
})

-- Autocompletion setup
cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expandable() then luasnip.expand()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
        if luasnip.jumpable(-1) then luasnip.jump(-1)
        else fallback()
        end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'emmet_vim' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' }
  }),
})

-- LSP keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, opts)
  end,
})

-- Custom command for ESLint fix
vim.api.nvim_create_user_command('EslintFixAll', function()
  vim.lsp.buf.format({ async = false })
end, {})

-- Optional: Mouse hover for diagnostics
vim.api.nvim_create_autocmd('CursorHold', {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false, scope = 'cursor' })
  end,
})
