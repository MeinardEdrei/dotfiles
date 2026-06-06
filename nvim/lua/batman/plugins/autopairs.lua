return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	-- Optional dependency
	dependencies = { "hrsh7th/nvim-cmp" },
	config = function()
		require("nvim-autopairs").setup({
			check_ts = true, -- Treesitter integration
			ts_config = {
				lua = { "string", "source" },
				javascript = { "string", "template_string" },
				java = false, -- Don't check treesitter on java
			},
			disable_filetype = { "TelescopePrompt", "spectre_panel", "dap-repl" },
			fast_wrap = {
				map = "<M-e>", -- Press <Alt-e> to wrap the word under cursor
				chars = { "{", "[", "(", '"', "'" },
				pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
				offset = 0, -- Offset from pattern match
				end_key = "$",
				keys = "qwertyuiopzxcvbnmasdfghjkl",
				check_comma = true,
				highlight = "PmenuSel",
				highlight_grey = "LineNr",
			},
		})

		-- If you want to automatically add `(` after selecting a function or method
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		local cmp = require("cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
	end,
}
