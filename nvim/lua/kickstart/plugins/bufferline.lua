return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers",
				separator_style = "slope",
				diagnostics = "nvim_lsp",
				always_show_bufferline = true,
				show_buffer_close_icons = true,
				show_close_icon = false,
				color_icons = true,
				show_duplicate_prefix = true,
				duplicates_across_groups = true,
				navigation_filtering = true,
				enforce_regular_tabs = false,
				persist_buffer_sort = true,
				offsets = {},

				truncate_names = true,
				-- Refined name formatter to handle empty paths safely
				name_formatter = function(buf)
					if buf.path == "" then
						return "[No Name]"
					end
					local name = vim.fn.fnamemodify(buf.path, ":t")
					if name:match("%.tsx$") then
						return name:gsub("%.tsx$", " ⚛")
					end
					return name
				end,

				-- Add a filter to ensure mini.files doesn't accidentally show up as a tab
				custom_filter = function(buf_number)
					if vim.bo[buf_number].filetype == "minifiles" then
						return false
					end
					return true
				end,
			},
		})
	end,
}
