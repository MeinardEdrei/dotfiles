return {
	{ -- Add indentation guides even on blank lines
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {
			-- The character to use for the indentation line
			indent = {
				char = "│", -- This is a nice thin line
				tab_char = "│",
			},
			-- Highlight the specific block you are currently inside
			scope = {
				enabled = true,
				show_start = false, -- Don't underline the start
				show_end = false, -- Don't underline the end
			},
			-- Don't show these lines in specific filetypes
			exclude = {
				filetypes = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"Trouble",
					"trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"lazyterm",
				},
			},
		},
	},
}
