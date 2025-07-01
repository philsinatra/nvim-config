-- General settings
vim.opt.number = true          -- Show line numbers
vim.opt.relativenumber = true  -- Relative line numbers
vim.opt.tabstop = 2            -- 2 spaces for tabs
vim.opt.shiftwidth = 2         -- 2 spaces for indent
vim.opt.expandtab = true       -- Use spaces instead of tabs
vim.opt.smartindent = true     -- Auto-indent new lines
vim.opt.wrap = true            -- Disable line wrapping
vim.opt.linebreak = true        -- Wrap at word boundries
vim.opt.textwidth = 120        -- Set wrap limit to 120 characters
vim.opt.wrapmargin = 0         -- Use textwidth instead of margin
vim.opt.cursorline = true      -- Highlight current line
vim.opt.termguicolors = true   -- Enable 24-bit RGB colors
vim.opt.mouse = 'a'            -- Enable mouse support
vim.opt.clipboard = 'unnamedplus' -- Use system clipboard
vim.opt.guicursor = 'n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50' -- Block cursor

-- Search settings
vim.opt.ignorecase = true      -- Case-insensitive searching
vim.opt.smartcase = true       -- Case-sensitive if uppercase used

-- Performance
vim.opt.updatetime = 250       -- Faster updates (for LSP, etc.)
vim.opt.timeoutlen = 300       -- Faster keymap timeout
