local M = {}

function M.setup()
	vim.opt.showtabline = 2

	-- 1. Define the Dark Color for the Separator
	--    We use an autocommand to ensure it stays dark even if you change themes.
	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = function()
			-- fg = "#333333" is a very dark grey. Change this hex code if you want it darker/lighter.
			vim.api.nvim_set_hl(0, "TabSeparator", { fg = "#333333", bg = "NONE" })
		end,
	})

	_G.close_tab_by_id = function(tabnr)
		vim.cmd("tabclose " .. tabnr)
	end

	_G.custom_tabline = function()
		local s = ""
		local current = vim.fn.tabpagenr()
		local total = vim.fn.tabpagenr("$")

		for i = 1, total do
			-- Highlight focused vs unfocused tabs
			if i == current then
				s = s .. "%#TabLineSel#"
			else
				s = s .. "%#TabLine#"
			end

			-- Mouse click handler
			s = s .. "%" .. i .. "T "

			-- Get buffer name
			local winnr = vim.fn.tabpagewinnr(i)
			local buflist = vim.fn.tabpagebuflist(i)
			local buf = buflist[winnr]
			local path = vim.api.nvim_buf_get_name(buf)
			local name = ""

			if path == "" then
				name = "[No Name]"
			else
				local parent = vim.fn.fnamemodify(path, ":p:h:t")
				local file = vim.fn.fnamemodify(path, ":t")
				name = parent .. "/" .. file
			end

			-- Add name
			s = s .. " " .. name .. " "

			-- Add Exit Button [x]
			s = s .. "%" .. i .. "@v:lua.close_tab_by_id@%#ErrorMsg# x %X"

			-- === THE CHANGE IS HERE ===
			-- Switch to our custom dark color, add the separator, then switch back to Fill
			s = s .. "%#TabSeparator#│"
		end

		s = s .. "%#TabLineFill#" return s
	end

	vim.opt.tabline = "%!v:lua.custom_tabline()"
end

return M
