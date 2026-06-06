local mini_files_km = require("batman.utils.mini-files")
local mini_files_git = require("batman.utils.mini-files-git")

return {
	"nvim-mini/mini.files",
	version = false, -- Force latest version
	opts = function(_, opts)
		-- Default keymaps
		opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, {
			close = "<esc>",
			go_in = "l",
			go_in_plus = "<CR>",
			go_out = "H",
			go_out_plus = "h",
			reset = ",",
			reveal_cwd = ".",
			show_help = "g?",
			synchronize = "s",
			trim_left = "<",
			trim_right = ">",
		})

		-- Custom keymaps definitions
		opts.custom_keymaps = {
			open_tmux_pane = "<M-t>",
			copy_to_clipboard = "<space>yy",
			zip_and_copy = "<space>yz",
			paste_from_clipboard = "<space>p",
			copy_path = "<M-c>",
			preview_image = "<space>i",
			preview_image_popup = "<M-i>",
		}

		-- Window options
		opts.windows = vim.tbl_deep_extend("force", opts.windows or {}, {
			preview = true,
			width_focus = 30,
			width_preview = 80,
		})

		-- Options
		opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
			use_as_default_explorer = true,
			permanent_delete = false,
		})

		return opts
	end,

	keys = {
		{
			"<leader>e",
			function()
				local buf_name = vim.api.nvim_buf_get_name(0)
				local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")
				if vim.fn.filereadable(buf_name) == 1 then
					require("mini.files").open(buf_name, true)
				elseif vim.fn.isdirectory(dir_name) == 1 then
					require("mini.files").open(dir_name, true)
				else
					require("mini.files").open(vim.uv.cwd(), true)
				end
			end,
			desc = "Open mini.files",
		},
		{
			"<leader>E",
			function()
				require("mini.files").open(vim.uv.cwd(), true)
			end,
			desc = "Open mini.files (cwd)",
		},
	},

	config = function(_, opts)
		require("mini.files").setup(opts)
		mini_files_km.setup(opts)
		mini_files_git.setup()
	end,
}
