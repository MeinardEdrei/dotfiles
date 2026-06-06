return {
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
}
