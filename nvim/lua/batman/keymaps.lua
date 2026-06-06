-- [[ KEYMAPS ]]
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
