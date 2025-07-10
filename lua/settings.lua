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

-- Cursor config
-- Block cursor for normal, visual, command, insert, and visual-enter modes.
-- With blinking settings for all modes.
vim.opt.guicursor = "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- Search settings
vim.opt.ignorecase = true      -- Case-insensitive searching
vim.opt.smartcase = true       -- Case-sensitive if uppercase used

-- Performance
vim.opt.updatetime = 250       -- Faster updates (for LSP, etc.)
vim.opt.timeoutlen = 300       -- Faster keymap timeout

-- Scrolling offset
vim.opt.scrolloff = 999
vim.opt.sidescrolloff = 999

-- Code folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- vim.opt.foldcolumn = "0"
vim.opt.foldtext = ""
vim.opt.foldlevelstart = 99 
vim.opt.foldlevel = 1 
-- vim.opt.foldnextmax = 4


