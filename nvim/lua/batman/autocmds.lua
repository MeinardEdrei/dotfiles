-- [[ AUTOCOMMANDS ]]
--  See `:help lua-guide-autocommands`

-- Re-apply WinSeparator highlight on every colorscheme change
-- (keeps the split line color consistent regardless of theme)
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		-- 'WinSeparator' controls the split line color
		vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#4a4e69", bold = true })
	end,
})

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
