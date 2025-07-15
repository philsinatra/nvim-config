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
    config = function()
      require('nvim-tree').setup({
        view = {
          side = "right",
          width = 50,
        },
      })
    end
  },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          file_ignore_patterns = {
            "node_modules/",
            "%.git/",
            "%.vscode/",
            "%.cache/",
            "%.mypy_cache/",
            "__pycache__/",
            "%.DS_Store",
            "dist/",
            "build/",
          },
        },
      })
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind [G]rep' })
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
      -- Dynamically determine linters based on available binaries
      local function get_linters_for_ft(ft)
        local linters = {}
        local eslint_bin = find_local_bin('eslint')
        local biome_bin = find_local_bin('biome')
        if ft == 'javascript' or ft == 'typescript' or ft == 'svelte' then
          if vim.fn.executable(eslint_bin) == 1 then
            table.insert(linters, 'eslint_d')
          elseif vim.fn.executable(biome_bin) == 1 then
            table.insert(linters, 'biome')
          end
        end
        if ft == 'svelte' or ft == 'css' then
          table.insert(linters, 'stylelint')
        end
        if ft == 'html' then
          table.insert(linters, 'htmlhint')
        end
        return linters
      end

      lint.linters_by_ft = {
        javascript = get_linters_for_ft('javascript'),
        typescript = get_linters_for_ft('typescript'),
        svelte = get_linters_for_ft('svelte'),
        html = get_linters_for_ft('html'),
        css = get_linters_for_ft('css'),
      }

      -- Configure linters
      lint.linters.eslint_d.cmd = find_local_bin('eslint_d')
      lint.linters.biome = {
        cmd = find_local_bin('biome'),
        args = { 'lint', '--stdin-file-path', vim.fn.expand('%:p') },
        stdin = true,
        stream = 'stdout',
        parser = function(output, bufnr)
          local diagnostics = {}
          if output == '' then return diagnostics end
          local ok, decoded = pcall(vim.json.decode, output)
          if not ok or not decoded.diagnostics then return diagnostics end
          for _, diag in ipairs(decoded.diagnostics) do
            table.insert(diagnostics, {
              bufnr = bufnr,
              lnum = (diag.location.line or 1) - 1,
              col = diag.location.column or 0,
              end_lnum = (diag.location.line or 1) - 1,
              end_col = diag.location.column or 0,
              message = diag.message or 'Unknown Biome error',
              severity = vim.diagnostic.severity[diag.severity and diag.severity:upper() or 'ERROR'] or vim.diagnostic.severity.ERROR,
              source = 'biome',
            })
          end
          return diagnostics
        end,
      }
      lint.linters.htmlhint.cmd = find_local_bin('htmlhint')
      lint.linters.stylelint.cmd = find_local_bin('stylelint')
      lint.linters.stylelint.args = {
        '--formatter', 'json',
        '--stdin',
        '--stdin-filename', function()
          return vim.fn.expand('%:p')
        end,
      }

      -- Add stylelint config if found
      local config_path = vim.fn.findfile('.stylelintrc.json', vim.fn.getcwd() .. ';')
      if config_path ~= '' and vim.fn.filereadable(config_path) == 1 then
        table.insert(lint.linters.stylelint.args, '--config')
        table.insert(lint.linters.stylelint.args, config_path)
      else
        vim.notify('Stylelint: No valid .stylelintrc.json found', vim.log.levels.WARN)
      end

      -- Custom parser for Stylelint JSON output
      lint.linters.stylelint.parser = function(output, bufnr)
        local diagnostics = {}
        if output == '' then return diagnostics end
        local ok, decoded = pcall(vim.json.decode, output)
        if not ok or not decoded then return diagnostics end
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
          local ft = vim.bo.filetype
          local linters = get_linters_for_ft(ft)
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
          javascript = function()
            local eslint_bin = find_local_bin('eslint')
            local biome_bin = find_local_bin('biome')
            if vim.fn.executable(eslint_bin) == 1 then
              return { 'prettier' } -- Use prettier with ESLint
            elseif vim.fn.executable(biome_bin) == 1 then
              return { 'biome' }
            end
            return { 'prettier' }
          end,
          typescript = function()
            local eslint_bin = find_local_bin('eslint')
            local biome_bin = find_local_bin('biome')
            if vim.fn.executable(eslint_bin) == 1 then
              return { 'prettier' }
            elseif vim.fn.executable(biome_bin) == 1 then
              return { 'biome' }
            end
            return { 'prettier' }
          end,
          svelte = function()
            local eslint_bin = find_local_bin('eslint')
            local biome_bin = find_local_bin('biome')
            if vim.fn.executable(eslint_bin) == 1 then
              return { 'prettier', 'stylelint' }
            elseif vim.fn.executable(biome_bin) == 1 then
              return { 'biome', 'stylelint' }
            end
            return { 'prettier', 'stylelint' }
          end,
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
            args = { 'check', '--write', '$FILENAME' },
            stdin = false,
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
-- require('nvim-tree').setup()
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
    'emmet_ls', -- Emmet
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
