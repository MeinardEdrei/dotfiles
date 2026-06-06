-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
	"nvim-neo-tree/neo-tree.nvim",
	enabled = false,
	version = "*",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- required for file icons
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree",
	keys = {
		{ "<C-n>", ":Neotree reveal<CR>", desc = "NeoTree reveal", silent = true },
	},
	opts = {
		default_component_configs = {
			git_status = {
				symbols = {
					added = "", -- Check mark (U+F00C)
					deleted = "", -- Minus box (U+F044)
					modified = "", -- Pencil (U+F54B)
					renamed = "➜", -- Heavy right-pointing arrow (U+279C) -- NEW
					untracked = "", -- Question mark (U+F128)
					ignored = "", -- Eye-slash (U+F474)
					unstaged = "●", -- Black circle (U+25CF) -- NEW
					staged = "", -- Checkered flag/Another check mark (U+F0C8)
					conflict = "", -- Zap/lightning (U+E727)
				},
			},
			icon = {
				folder_closed = "", -- Folder icon (U+E6C0)
				folder_open = "", -- Open folder icon (U+E6C6)
				folder_empty = "  ", -- Empty folder icon (U+FACC)
			},
		},
		filesystem = {
			window = {
				mappings = {
					["<C-n>"] = "close_window",
				},
			},
		},
	},
}
