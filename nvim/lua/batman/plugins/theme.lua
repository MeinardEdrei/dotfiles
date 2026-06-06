return { -- Theme
	"catppuccin/nvim",
	priority = 1000,
	init = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = false,
			term_colors = true,

			integrations = {
				cmp = true,
				gitsigns = true,
				treesitter = true,
				telescope = { enabled = true },
				mini = { enabled = true },
				snacks = true, -- Added snacks integration just in case
				native_lsp = {
					enabled = true,
					virtual_text = {
						errors = { "italic" },
						hints = { "italic" },
						warnings = { "italic" },
						information = { "italic" },
					},
					underlines = {
						errors = { "undercurl" },
						hints = { "undercurl" },
						warnings = { "undercurl" },
						information = { "undercurl" },
					},
				},
			},

			custom_highlights = function(colors)
				return {
					-- GitSigns Blame
					GitSignsCurrentLineBlame = { fg = colors.subtext0, style = { "italic" } },

					-- GLOBAL FLOATING WINDOWS
					FloatBorder = { fg = "#262B34", bg = colors.base },
					NormalFloat = { bg = colors.base },

					NoiceCmdlinePopup = { bg = colors.base },
					NoiceCmdlinePopupBorder = { fg = "#262B34", bg = colors.base },
					NoiceCmdlinePopupBorderSearch = { fg = "#262B34", bg = colors.base },
					NoiceCmdlinePrompt = { bg = colors.base, fg = colors.blue },
				}
			end,

			color_overrides = {
				mocha = {
					base = "#0C0E12",
					mantle = "#12151A",
					crust = "#181C22",

					surface0 = "#1F232B",
					surface1 = "#262B34",
					surface2 = "#303640",

					text = "#B4B6C4",
					subtext1 = "#9496A4",
					subtext0 = "#787A88",

					overlay0 = "#3D424D",
					overlay1 = "#484E5A",
					overlay2 = "#535967",

					teal = "#7AC5B4",
					sapphire = "#7AC5B4",
					sky = "#78B4CC",

					red = "#D47272",
					maroon = "#D47272",
					mauve = "#D47272",

					pink = "#D495A5",
					flamingo = "#D48888",
					rosewater = "#D4A8B0",
					lavender = "#9580D4",
					blue = "#7BA3D9",
					green = "#88B88A",
					yellow = "#C5A875",
					peach = "#D4937D",
				},
			},
		})

		vim.cmd.colorscheme("catppuccin")
		vim.cmd.hi("Comment gui=none")

		-- [[ MANUAL OVERRIDES ]]
		local bg = "#0C0E12"
		local border = "#262B34" -- If you want pure black borders again, change this to "#000000"

		vim.api.nvim_set_hl(0, "NoiceCmdlinePopup", { bg = bg })
		vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { fg = border, bg = bg })
		vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorderSearch", { fg = border, bg = bg })
	end,
}
