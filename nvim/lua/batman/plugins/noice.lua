return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		{
			"rcarriga/nvim-notify",
			opts = {
				background_colour = "#000000",
				render = "wrapped-compact",
				stages = "fade",
				timeout = 3000,
			},
		},
	},
	opts = {
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = true,
			inc_rename = false,
			lsp_doc_border = true,
		},

		-- [[ VIEWS CONFIGURATION ]]
		views = {
			-- 1. THE INPUT BOX (Top part of the container)
			cmdline_popup = {
				position = { row = "40%", col = "50%" }, -- Placed at top-third of screen
				size = {
					width = "auto",
					height = "auto",
				},
				border = {
					style = "rounded",
					padding = { 0, 1 },
				},
				win_options = {
					-- Use the specific highlight groups we made in init.lua
					winhighlight = "Normal:NoiceCmdlinePopup,FloatBorder:NoiceCmdlinePopupBorder",
				},
			},

			-- 2. THE SUGGESTIONS LIST (Bottom part of the container)
			popupmenu = {
				relative = "editor",
				position = { row = "40% + 3", col = "50%" },
				size = {
					width = "50%", -- Must match cmdline_popup width exactly
					height = "10", -- Tall enough to show many suggestions
				},
				border = {
					style = "rounded",
					padding = { 0, 1 },
				},
				win_options = {
					-- Use the standard float colors (Deep Midnight BG / Black Border)
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				},
			},

			-- 3. CONFIRMATION DIALOGS (mini.files prompts)
			confirm = {
				border = {
					style = "rounded",
					padding = { 0, 1 },
				},
				win_options = {
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				},
			},
		},

		routes = {
			{
				filter = { event = "msg_show", kind = "", find = "written" },
				opts = { skip = true },
			},
			{
				filter = { event = "notify", find = "No information available" },
				opts = { skip = true },
			},
		},
	},
}
