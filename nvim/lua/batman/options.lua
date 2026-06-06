-- [[ OPTIONS ]]
-- NOTE: vim.g.mapleader and vim.g.maplocalleader are set in init.lua
--       because they must be defined before lazy.nvim loads.

vim.opt.termguicolors = true
vim.g.have_nerd_font = true
vim.opt.number = true
vim.opt.cmdheight = 1

-- Suppress the 'Press ENTER' prompt after many commands and messages.
-- 'shortmess' tells Neovim what messages to skip pausing for.
-- 'A' skips the "hit ENTER" prompt on new file/buffer creation.
vim.opt.shortmess:append("A")

-- [Code Indention]
vim.opt.tabstop = 2 -- Set tab width to 2 spaces
vim.opt.shiftwidth = 2 -- Number of spaces for auto-indent
vim.opt.softtabstop = 2 -- Makes backspace delete 2 spaces
vim.opt.expandtab = true -- Converts tabs to spaces
vim.opt.autoindent = true -- Copy the previous line's indent
vim.opt.smartindent = true -- Intelligent indentation based on syntax

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
vim.opt.clipboard = "unnamedplus"

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Ensure auto-session has all the options it needs
vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
