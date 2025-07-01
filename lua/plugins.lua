-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Helper function to find local binaries
local function find_local_bin(bin_name)
  -- Prefer project node_modules for stylelint to access postcss-html
  if bin_name == 'stylelint' then
    local project_root = vim.fn.getcwd()
    local node_bin = project_root .. '/node_modules/.bin/' .. bin_name
    if vim.fn.executable(node_bin) == 1 then
      return node_bin
    end
  end
  -- Check Mason's binary path
  local mason_bin = vim.fn.stdpath('data') .. '/mason/bin/' .. bin_name
  if vim.fn.executable(mason_bin) == 1 then
    return mason_bin
  end
  -- Fallback to node_modules for other binaries
  local project_root = vim.fn.getcwd()
  local node_bin = project_root .. '/node_modules/.bin/' .. bin_name
  if vim.fn.executable(node_bin) == 1 then
    return node_bin
  end
  -- Fallback to global binary
  return bin_name
end

-- Plugin list
require('lazy').setup({
  -- Colorscheme
  { 'rose-pine/neovim', name = 'rose-pine', priority = 1000 },

  -- File explorer
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          -- Add file_ignore_patterns here
          file_ignore_patterns = {
            "node_modules/",
            "%.git/",       -- To ignore .git directory
            "%.vscode/",    -- To ignore .vscode if you use it
            "%.cache/",     -- General cache directories
            "%.mypy_cache/",
            "__pycache__/", -- Python specific
            "%.DS_Store",   -- macOS specific
            "dist/",        -- Common build output
            "build/",       -- Common build output
          },
          -- You can also configure specific pickers here if needed
          -- find_files = {
          --   -- For example, to always pass --no-require-git to rg/fd
          --   find_command = { "rg", "--files", "--color", "never", "--no-require-git" }
          -- }
        },
      })

      -- Optional: Set up keymaps here if you haven't already
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind [G]rep' })
      -- ... other telescope keymaps
    end,
  },

  -- Treesitter for syntax highlighting
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },

  -- Mason for managing LSPs, linters, and formatters
  { 'mason-org/mason.nvim' },
  { 'mason-org/mason-lspconfig.nvim' },
  { 'WhoIsSethDaniel/mason-tool-installer.nvim' },

  -- LSP and autocompletion
  { 'neovim/nvim-lspconfig' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  { 'L3MON4D3/LuaSnip' },

  -- Statusline
  { 'nvim-lualine/lualine.nvim' },

  -- Git integration
  { 'lewis6991/gitsigns.nvim' },

  -- Autopairs
  { 'windwp/nvim-autopairs' },

  -- Emmet
  -- {
  --     'mattn/emmet-vim',
  --     config = function()
  --         vim.g.user_emmet_mode = 'a'  -- Enable in all modes
  --         vim.g.user_emmet_leader_key = '<C-e>'
  --         -- vim.g.user_emmet_install_global = 1
  --         vim.g.user_emmet_settings = {
  --             svelte = { extends = 'html' },
  --             javascript = { extends = 'jsx' },
  --             typescript = { extends = 'tsx' }
  --         }
  --         -- Filetype detection
  --         vim.g.user_emmet_expandabbr_key = '<C-e>,'
  --         vim.cmd([[
  --             autocmd FileType html,css,svelte,javascript,typescript,jsx,tsx EmmetInstall
  --             autocmd FileType html setlocal omnifunc=emmet#completeTag
  --         ]])
  --     end,
  -- },

  -- Replace the entire mattn/emmet-vim block with:
  {
    'olrtg/nvim-emmet',
    config = function()
      vim.keymap.set({ "n", "v" }, '<leader>xe', require('nvim-emmet').wrap_with_abbreviation)
    end,
  },

  -- Linting with nvim-lint
  {
    'mfussenegger/nvim-lint',
    config = function()
      local lint = require('lint')
      lint.linters_by_ft = {
        javascript = { 'eslint_d' },
        typescript = { 'eslint_d' },
        svelte = { 'eslint_d', 'stylelint' },
        html = { 'htmlhint' },
        css = { 'stylelint' },
      }

      -- Configure linters
      lint.linters.eslint_d.cmd = find_local_bin('eslint_d')
      lint.linters.htmlhint.cmd = find_local_bin('htmlhint')
      lint.linters.stylelint.cmd = find_local_bin('stylelint')
      lint.linters.stylelint.args = {
        '--formatter', 'json',
        '--stdin',
        '--stdin-filename', function()
          return vim.fn.expand('%:p')
        end,
      }

      -- Add config if found
      local config_path = vim.fn.findfile('.stylelintrc.json', vim.fn.getcwd() .. ';')
      -- vim.notify('Stylelint: Config path: ' .. (config_path or 'none'), vim.log.levels.INFO)
      if config_path ~= '' and vim.fn.filereadable(config_path) == 1 then
        table.insert(lint.linters.stylelint.args, '--config')
        table.insert(lint.linters.stylelint.args, config_path)
      else
        vim.notify('Stylelint: No valid .stylelintrc.json found', vim.log.levels.WARN)
      end

      -- Custom parser for Stylelint JSON output
      lint.linters.stylelint.parser = function(output, bufnr)
        local diagnostics = {}
        -- Debug: Log buffer content
        local buf_content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
        -- vim.notify('Stylelint: Buffer content: ' .. vim.inspect(buf_content), vim.log.levels.DEBUG)
        if output == '' then
          -- vim.notify('Stylelint: Empty output', vim.log.levels.WARN)
          return diagnostics
        end
        -- vim.notify('Stylelint: Raw output: ' .. vim.inspect(output), vim.log.levels.DEBUG)
        local ok, decoded = pcall(vim.json.decode, output)
        if not ok or not decoded then
          -- vim.notify('Stylelint: Failed to parse JSON: ' .. output, vim.log.levels.ERROR)
          return diagnostics
        end
        for _, result in ipairs(decoded) do
          if result.warnings and #result.warnings > 0 then
            for _, warning in ipairs(result.warnings) do
              table.insert(diagnostics, {
                bufnr = bufnr,
                lnum = (warning.line or 1) - 1,
                col = (warning.column or 1) - 1,
                end_lnum = (warning.line or 1) - 1,
                end_col = warning.column or 1,
                message = warning.text or 'Unknown Stylelint error',
                severity = vim.diagnostic.severity[warning.severity and warning.severity:upper() or 'ERROR'] or vim.diagnostic.severity.ERROR,
                source = 'stylelint',
              })
            end
          end
        end
        return diagnostics
      end

      -- Trigger linting
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
        callback = function()
          local linters = lint.linters_by_ft[vim.bo.filetype] or {}
          for _, linter in ipairs(linters) do
            local cmd = lint.linters[linter].cmd
            if cmd and vim.fn.executable(cmd) == 1 then
              lint.try_lint(linter)
            else
              vim.notify('Linter ' .. linter .. ' not executable: ' .. cmd, vim.log.levels.ERROR)
            end
          end
        end,
      })
    end,
  },

  -- Formatting with conform.nvim
  {
    'stevearc/conform.nvim',
    config = function()
      require('conform').setup({
        formatters_by_ft = {
          javascript = { 'prettier', 'biome' },
          typescript = { 'prettier', 'biome' },
          svelte = { 'prettier', 'biome', 'stylelint' },
          html = { 'prettier' },
          css = { 'stylelint', 'prettier' },
          json = { 'prettier' },
        },
        formatters = {
          prettier = {
            command = find_local_bin('prettier'),
            args = { '--stdin-filepath', '$FILENAME' },
          },
          biome = {
            command = find_local_bin('biome'),
            args = { 'check', '--apply', '--stdin-file-path', '$FILENAME' },
          },
          stylelint = {
            command = find_local_bin('stylelint'),
            args = {
              '--fix',
              '--stdin',
              '--stdin-filename',
              '$FILENAME',
            },
            stdin = true,
          },
        },
      })
      vim.api.nvim_create_autocmd('BufWritePre', {
        callback = function()
          require('conform').format({ async = false, lsp_fallback = true })
        end,
      })
    end,
  },
})

-- Colorscheme setup
require('rose-pine').setup({
  variant = 'auto',
  dark_variant = 'main',
  styles = { bold = true, italic = true, transparency = true },
})
vim.cmd([[colorscheme rose-pine]])

-- Update lualine to use rose-pine
require('lualine').setup({ options = { theme = 'rose-pine' } })

-- Basic plugin setups
require('nvim-tree').setup()
require('gitsigns').setup()
require('nvim-autopairs').setup()

-- Treesitter
require('nvim-treesitter.configs').setup({
  ensure_installed = { 'html', 'css', 'javascript', 'typescript', 'tsx', 'json', 'svelte' },
  highlight = { enable = true },
  indent = { enable = true },
})

-- Mason setup
require('mason').setup()
require('mason-lspconfig').setup()
require('mason-tool-installer').setup({
  ensure_installed = {
    -- LSPs
    'ts_ls', -- TypeScript
    'svelte', -- Svelte
    'emmet-ls', -- Emmet
    'eslint', -- ESLint
    'cssls', -- CSS
    'html', -- HTML
    -- Linters
    'eslint_d', -- ESLint daemon
    'stylelint', -- Stylelint
    'htmlhint', -- HTMLHint
    -- Formatters
    'prettier', -- Prettier
    'biome', -- Biome
  },
  auto_update = true,
})

-- LSP config for HTML
require('lspconfig').html.setup({
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  init_options = {
    configurationSection = { "html", "css", "javascript" },
    embeddedLanguages = {
      css = true,
      javascript = true
    },
    provideFormatter = true
  }
})

-- Emmet Language Server
require('lspconfig').emmet_ls.setup({
  filetypes = {
    "html",
    "css",
    "javascript",
    "typescript",
    "javascriptreact", -- For JSX
    "typescriptreact", -- For TSX
    "svelte",
  },
  init_options = {
    html = {
      options = {
        -- You can add Emmet-specific options here if needed,
        -- for example, to control self-closing tags or other behaviors.
        -- See Emmet LS documentation for available options.
      }
    }
  }
})
