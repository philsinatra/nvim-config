local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader key
vim.g.mapleader = ' '

-- File explorer
map('n', '<leader>kb', ':NvimTreeToggle<CR>', opts)

-- Telescope (fuzzy finder)
map('n', '<leader>ff', '<cmd>Telescope find_files<CR>', opts)
map('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', opts)
map('n', '<leader>fd', '<cmd>Telescope diagnostics<CR>', opts) -- Added for diagnostics

-- Buffer navigation
map('n', '<Tab>', ':bnext<CR>', opts)
map('n', '<S-Tab>', ':bprevious<CR>', opts)
map('n', '<leader>bd', ':bdelete<CR>', opts)

-- LSP keymaps (defined in lsp.lua)

-- Git integrations
map('n', '<leader>gb', ':Gitsigns blame_line<CR>', opts)
map('n', '<leader>gd', ':Gitsigns diffthis<CR>', opts)

-- Emmet expansion keymap
-- map('i', '<C-e>,', '<Plug>(emmet-expand-abbr)', opts)

-- Formatting with conform.nvim
map('n', '<leader>f', function() require('conform').format({ async = false, lsp_fallback = true }) end, opts)

-- Show diagnostic details
map('n', '<leader>e', function() vim.diagnostic.open_float() end, opts)

-- Custom keybindings
vim.keymap.set('n', '<A-Down>', ':m .+1<CR>', {noremap = true, silent = true}) -- Move line down
vim.keymap.set('n', '<A-Up>', ':m .-2<CR>', {noremap = true, silent = true}) -- Move line up
vim.keymap.set('n', '<leader>d', ':bp<bar>bd#<CR>', { desc = 'Delete buffer and go to previous' })
