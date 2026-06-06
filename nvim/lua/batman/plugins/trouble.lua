return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		focus = true, -- Focus the window when opened
	},
	keys = {
		-- Toggle the diagnostic list
		{
			"<leader>qQ",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
		-- Toggle the list only for the current file
		{
			"<leader>q",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
		},
		-- Jump to next/prev error using Trouble
		{
			"]t",
			"<cmd>Trouble next<cr>",
			desc = "Next Trouble item",
		},
		{
			"[t",
			"<cmd>Trouble prev<cr>",
			desc = "Previous Trouble item",
		},
	},
}
