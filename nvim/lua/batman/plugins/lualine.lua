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
-- THEME & COLORS (Synced with your Catppuccin Mocha overrides)
-- ----------------------------------------------------------------------

local colors = {
	bg = "#0C0E12",
	surface = "#1F232B",
	text = "#B4B6C4",
	subtext = "#787A88",
	blue = "#7BA3D9",
	green = "#88B88A",
	lavender = "#9580D4",
	yellow = "#C5A875",
	red = "#D47272",
}

local custom_theme = {
	normal = {
		a = { fg = colors.bg, bg = colors.blue, bold = true },
		b = { fg = colors.text, bg = colors.surface },
		c = { fg = colors.subtext, bg = colors.bg },
		x = { fg = colors.subtext, bg = colors.bg },
		y = { fg = colors.text, bg = colors.surface },
		z = { fg = colors.bg, bg = colors.blue, bold = true },
	},
	insert = {
		a = { fg = colors.bg, bg = colors.green, bold = true },
		b = { fg = colors.text, bg = colors.surface },
		c = { fg = colors.subtext, bg = colors.bg },
		x = { fg = colors.subtext, bg = colors.bg },
		y = { fg = colors.text, bg = colors.surface },
		z = { fg = colors.bg, bg = colors.green, bold = true },
	},
	visual = {
		a = { fg = colors.bg, bg = colors.lavender, bold = true },
		b = { fg = colors.text, bg = colors.surface },
		c = { fg = colors.subtext, bg = colors.bg },
		x = { fg = colors.subtext, bg = colors.bg },
		y = { fg = colors.text, bg = colors.surface },
		z = { fg = colors.bg, bg = colors.lavender, bold = true },
	},
	command = {
		a = { fg = colors.bg, bg = colors.yellow, bold = true },
		b = { fg = colors.text, bg = colors.surface },
		c = { fg = colors.subtext, bg = colors.bg },
		x = { fg = colors.subtext, bg = colors.bg },
		y = { fg = colors.text, bg = colors.surface },
		z = { fg = colors.bg, bg = colors.yellow, bold = true },
	},
	replace = {
		a = { fg = colors.bg, bg = colors.red, bold = true },
		b = { fg = colors.text, bg = colors.surface },
		c = { fg = colors.subtext, bg = colors.bg },
		x = { fg = colors.subtext, bg = colors.bg },
		y = { fg = colors.text, bg = colors.surface },
		z = { fg = colors.bg, bg = colors.red, bold = true },
	},
	inactive = {
		a = { fg = colors.subtext, bg = colors.bg },
		b = { fg = colors.subtext, bg = colors.bg },
		c = { fg = colors.subtext, bg = colors.bg },
		x = { fg = colors.subtext, bg = colors.bg },
		y = { fg = colors.subtext, bg = colors.bg },
		z = { fg = colors.subtext, bg = colors.bg },
	},
}

-- ----------------------------------------------------------------------
-- LUALINE CONFIG
-- ----------------------------------------------------------------------

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
	opts = {
		options = {
			theme = custom_theme,
			component_separators = "",
			section_separators = { left = "", right = "" },
			globalstatus = true,
			disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
		},
		sections = {
			-- LEFT SIDE
			lualine_a = {
				{ "mode", fmt = function(str) return " " .. str end, separator = { left = "" } },
			},
			lualine_b = {
				{ "branch", icon = "" },
				{
					"diff",
					symbols = { added = " ", modified = " ", removed = " " },
					cond = function()
						return vim.o.columns > 120
					end,
				},
				{
					macro_recording,
					color = { fg = colors.yellow, bold = true },
				},
			},
			lualine_c = {
				-- FILENAME (Prioritized Floating Capsule)
				{
					"filename",
					path = 1,
					symbols = { modified = " ●", readonly = " 🔒", unnamed = "[No Name]" },
					separator = { left = "", right = "" },
					color = { bg = colors.surface, fg = colors.text },
				},
			},

			-- RIGHT SIDE
			lualine_x = {
				{
					nearest_diagnostic,
					color = { fg = colors.red, bold = true },
				},
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = { error = " ", warn = " ", info = " ", hint = " " },
					-- HIDE Standard Diagnostics if window is super tiny (< 80 cols)
					cond = function()
						return vim.o.columns > 80
					end,
				},
				{
					lsp_clients,
					color = { fg = colors.lavender, italic = true },
				},
			},
			lualine_y = {
				{ "progress", separator = { left = "" } },
			},
			lualine_z = {
				{ "location", separator = { right = "" } },
			},
		},
		extensions = { "quickfix", "man", "fugitive", "lazy" },
	},
}
