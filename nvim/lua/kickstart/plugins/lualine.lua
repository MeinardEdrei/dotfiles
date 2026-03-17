-- ----------------------------------------------------------------------
-- HELPER FUNCTIONS
-- ----------------------------------------------------------------------

-- 1. Your Custom Nearest Diagnostic Logic (Preserved & Optimized)
local function nearest_diagnostic()
	local diagnostics = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	-- Filter and sort errors by proximity to the current line
	if #diagnostics > 0 then
		table.sort(diagnostics, function(a, b)
			local current_line = vim.fn.line(".")
			return math.abs(a.lnum - current_line) < math.abs(b.lnum - current_line)
		end)
		local nearest = diagnostics[1]
		local line_num = nearest.lnum + 1
		local current_line = vim.fn.line(".")
		if line_num ~= current_line then
			return " " .. line_num
		end
	end

	-- Check for warnings if no error found
	local warnings = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
	if #warnings > 0 then
		table.sort(warnings, function(a, b)
			local current_line = vim.fn.line(".")
			return math.abs(a.lnum - current_line) < math.abs(b.lnum - current_line)
		end)
		local nearest = warnings[1]
		local line_num = nearest.lnum + 1
		local current_line = vim.fn.line(".")
		if line_num ~= current_line then
			return " " .. line_num
		end
	end
	return ""
end

-- 2. Show active LSP clients (e.g., "lua_ls, null-ls")
local function lsp_clients()
	-- If screen is narrower than 120 chars, hide LSP entirely to save space
	if vim.o.columns < 120 then
		return ""
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if #clients == 0 then
		return ""
	end

	local names = {}
	for _, client in pairs(clients) do
		table.insert(names, client.name)
	end

	-- if vim.o.columns < 120 then return " " end

	return "  " .. table.concat(names, ", ")
end

-- 3. Show Macro Recording Status (Very useful!)
local function macro_recording()
	local reg = vim.fn.reg_recording()
	if reg == "" then
		return ""
	end
	return " @" .. reg
end

-- ----------------------------------------------------------------------
-- LUALINE CONFIG
-- ----------------------------------------------------------------------

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim", },
	opts = {
		options = {
			theme = "catppuccin-mocha",
			component_separators = "",
			section_separators = { left = "", right = "" },
			globalstatus = true,
			disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
		},
		sections = {
			-- LEFT SIDE
			lualine_a = {
				{ "mode", separator = { left = "" }, right_padding = 2 },
			},
			lualine_b = {
				"branch",
				{
					"diff",
					symbols = { added = " ", modified = " ", removed = " " },
					cond = function()
						return vim.o.columns > 120
					end,
				},
				{
					macro_recording,
					color = { fg = "#ff9e64", gui = "bold" },
				},
			},
			lualine_c = {
				-- FILENAME (Prioritized)
				{
					"filename",
					path = 1,
					symbols = { modified = "  ", readonly = "", unnamed = "" },
				},
			},

			-- RIGHT SIDE
			lualine_x = {
				{
					nearest_diagnostic,
					color = { fg = "#f7768e", gui = "bold" },
				},
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = { error = " ", warn = " ", info = " " },
					-- HIDE Standard Diagnostics if window is super tiny (< 80 cols)
					cond = function()
						return vim.o.columns > 80
					end,
				},
				{
					lsp_clients, -- This now checks width internally (see function above)
					icon = "",
					color = { fg = "#b4befe", gui = "italic" },
				},
			},
			lualine_y = { "progress" },
			lualine_z = {
				{ "location", separator = { right = "" }, left_padding = 2 },
			},
		},
		extensions = { "quickfix", "man", "fugitive", "lazy" },
	},
}
