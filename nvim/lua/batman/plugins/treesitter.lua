return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,
	priority = 1000,
	dependencies = {
		{
			"windwp/nvim-ts-autotag",
			config = function()
				require("nvim-ts-autotag").setup({
					opts = {
						enable_close = true,
						enable_rename = true,
						enable_close_on_slash = false,
					},
				})
			end,
		},
	},
	config = function()
		-- v1.0 setup only accepts install_dir; ensure_installed/auto_install are not supported
		require("nvim-treesitter").setup()

		local wanted = {
			"bash", "c", "diff", "html", "lua", "luadoc",
			"markdown", "markdown_inline", "query", "vim", "vimdoc",
			"javascript", "typescript", "tsx", "python", "c_sharp",
		}
		vim.schedule(function()
			local installed = require("nvim-treesitter").get_installed()
			local missing = vim.tbl_filter(function(p)
				return not vim.list_contains(installed, p)
			end, wanted)
			if #missing > 0 then
				require("nvim-treesitter").install(missing)
			end
		end)
		-- New v1.0 API: highlight must be started manually per buffer
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})
		-- Must run after built-in ftplugins (e.g. indent/html.vim sets HtmlIndent())
		-- so we use a second autocmd with nested=true to fire after all ftplugins settle
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				vim.schedule(function()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end)
			end,
		})
	end,
}
