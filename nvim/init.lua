vim.g.mapleader = " "
vim.g.maplocalleader = " "
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

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		-- 'WinSeparator' controls the split line color
		vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#4a4e69", bold = true })
	end,
})

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- [[ Bufferline ]]
vim.keymap.set("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", { desc = "Pin/Unpin Buffer" })
vim.keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close all other buffers" })
vim.keymap.set("n", "<leader>br", "<cmd>BufferLineCloseRight<CR>", { desc = "Close buffers to the right" })
vim.keymap.set("n", "<leader>n", "<cmd>enew<CR>", { desc = "New Empty Buffer" })
vim.keymap.set("n", "gb", "<cmd>BufferLinePick<CR>", { desc = "Jump to Buffer" })

-- Navigate between buffers (tabs)
vim.keymap.set("n", "H", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Buffer" })
vim.keymap.set("n", "L", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Buffer" })

-- Re-order buffers (Move them left/right)
vim.keymap.set("n", "<leader>bh", "<cmd>BufferLineMovePrev<CR>", { desc = "Move Buffer Left" })
vim.keymap.set("n", "<leader>bl", "<cmd>BufferLineMoveNext<CR>", { desc = "Move Buffer Right" })

-- Close current buffer (the tab at the top)
vim.keymap.set("n", "<leader>x", function()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo.modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
    if choice == 1 then -- Yes
      vim.cmd.write()
      vim.cmd.bdelete(bufnr)
    elseif choice == 2 then -- No (Force close)
      vim.cmd.bdelete({ args = { bufnr }, bang = true })
    end
  else
    vim.cmd.bdelete(bufnr)
  end
end, { desc = "Close Buffer (Tab)" })

-- [[ Window & Split Management ]]

-- Move current split into its own new Tab
vim.keymap.set("n", "<leader>N", "<C-w>T", { desc = "[B]reak split to new Tab" })
--    Split window Vertically (Left/Right)
vim.keymap.set("n", "<leader>v", "<C-w>v", { desc = "Split [V]ertical" })
--    Split window Horizontally (Up/Down)
vim.keymap.set("n", "<leader>j", "<C-w>s", { desc = "Split Horizontal [-]" })
--    If you are in a split, it closes the split.
--    If you dragged borders and messed up sizes, this resets them to equal
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalize Window Sizes" })
-- Maximize current split height
vim.keymap.set("n", "<leader>zj", "<C-w>_", { desc = "Maximize current split height" })
-- Maximize current split width
vim.keymap.set("n", "<leader>zz", "<C-w>|", { desc = "Maximize current split width" })
-- Reset/Equalize sizes (use this to "un-maximize" and reset all splits)
vim.keymap.set("n", "<leader>zx", "<C-w>=", { desc = "Equalize Window Sizes" })

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
-- Move to the next diagnostic (error/warning) in the buffer
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
-- Move to the previous diagnostic
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
-- Open a floating window with the error message (if it's truncated or you want to read it clearly)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
-- Open the list of all errors in the project (you already have this one mapped to <leader>q)
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- TMUX AUTO-RENAMING
-- if os.getenv("TMUX") then
-- 	local autocmd = vim.api.nvim_create_autocmd
-- 	local augroup = vim.api.nvim_create_augroup
-- 	local tmux_group = augroup("TmuxWindowRename", { clear = true })
--
-- 	autocmd({ "BufEnter", "WinEnter", "FocusGained" }, {
-- 		group = tmux_group,
-- 		callback = function()
-- 			-- 1. Get the properties of the current buffer
-- 			local buftype = vim.bo.buftype
-- 			local filetype = vim.bo.filetype
-- 			local filename = vim.fn.expand("%:t")
--
-- 			-- 2. IGNORE "nofile" buffers (like floating windows, telescope, null-ls, etc.)
-- 			--    If we are in one of these, do nothing (keep the previous window name)
-- 			if buftype == "nofile" or buftype == "prompt" or buftype == "popup" then
-- 				return
-- 			end
--
-- 			-- 3. Handle specific plugins (optional optimization)
-- 			if filetype == "TelescopePrompt" or filetype == "neo-tree" or filetype == "lazy" then
-- 				return
-- 			end
--
-- 			-- 4. Set default name if filename is empty (e.g. new unsaved file)
-- 			if filename == "" or filename == nil then
-- 				filename = "[No Name]" -- Or just "nvim" if you prefer
-- 			end
--
-- 			-- 5. Handle Terminal buffers specially
-- 			if buftype == "terminal" then
-- 				filename = "term"
-- 			end
--
-- 			-- 6. Execute the rename command
-- 			vim.schedule(function()
-- 				vim.fn.system("tmux rename-window '" .. filename .. "'")
-- 			end)
-- 		end,
-- 	})
--
-- 	-- Reset when closing Neovim
-- 	autocmd("VimLeave", {
-- 		group = tmux_group,
-- 		callback = function()
-- 			vim.fn.system("tmux set-window-option automatic-rename on")
-- 		end,
-- 	})
-- end

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- NOTE: LAZY SETUP

require("lazy").setup({

	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		version = false,
		opts = {
			image = { enabled = true },
		},
	},

	{ -- Git Conflicts
		"akinsho/git-conflict.nvim",
		config = true, -- Simply requires the plugin and runs default setup
		keys = {
			-- Keymaps for navigating and resolving conflicts
			{ "<leader>gc", "<cmd>GitConflictNextConflict<CR>", desc = "Git: Next Conflict" },
			{ "<leader>gp", "<cmd>GitConflictPrevConflict<CR>", desc = "Git: Previous Conflict" },
			{ "<leader>go", "<cmd>GitConflictOur<CR>", desc = "Git: Accept OURS" },
			{ "<leader>gt", "<cmd>GitConflictTheirs<CR>", desc = "Git: Accept THEIRS" },
			{ "<leader>gb", "<cmd>GitConflictBoth<CR>", desc = "Git: Accept BOTH" },
			{ "<leader>g0", "<cmd>GitConflictNone<CR>", desc = "Git: Accept NONE (Remove All)" },
		},
	},

	{ -- Colorizer
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPre",
		opts = { -- set to setup table
		},
	},

	{ -- Auto tag
		"windwp/nvim-ts-autotag",
		dependencies = "nvim-treesitter/nvim-treesitter",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},

	-- { -- Auto Save
	-- 	"pocco81/auto-save.nvim",
	-- 	config = function()
	-- 		require("auto-save").setup()
	-- 	end,
	-- },

	-- LSP Plugins
	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},

	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	-- NOTE: PLUGINS HERE

	require("kickstart.plugins.debug"),
	require("kickstart.plugins.indent_line"),
	require("kickstart.plugins.lint"),
	require("kickstart.plugins.autopairs"),
	require("kickstart.plugins.nvim_tmux_navigator"),
	-- require("kickstart.plugins.neo-tree"),
	require("kickstart.plugins.mini"),
	require("kickstart.plugins.lsp-config"),
	require("kickstart.plugins.gitsigns"),
	require("kickstart.plugins.telescope"),
	require("kickstart.plugins.treesitter"),
	require("kickstart.plugins.lualine"),
	require("kickstart.plugins.autocompletion"),
	require("kickstart.plugins.auto-session"),
	require("kickstart.plugins.noice"),
	require("kickstart.plugins.theme"),
	require("kickstart.plugins.conform"),
	require("kickstart.plugins.which-key"),
	require("kickstart.plugins.trouble"),
	require("kickstart.plugins.bufferline"),

	-- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
	--    This is the easiest way to modularize your config.
	--
	--  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
	-- { import = 'custom.plugins' },
	--
	-- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
	-- Or use telescope!
	-- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
	-- you can continue same window with `<space>sr` which resumes last telescope search
}, {
	ui = {
		-- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
