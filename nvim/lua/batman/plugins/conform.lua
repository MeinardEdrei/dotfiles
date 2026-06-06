return { -- Autoformat
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "", -- This allows it to work in Normal AND Visual mode (great for partial formatting)
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		notify_on_error = false,
		format_on_save = false,
		-- format_on_save = function(bufnr)
		-- 	-- Disable "format_on_save lsp_fallback" for languages that don't
		-- 	-- have a well standardized coding style. You can add additional
		-- 	-- languages here or re-enable it for the disabled ones.
		-- 	local disable_filetypes = { c = true, cpp = true }
		-- 	local lsp_format_opt
		-- 	if disable_filetypes[vim.bo[bufnr].filetype] then
		-- 		lsp_format_opt = "never"
		-- 	else
		-- 		lsp_format_opt = "fallback"
		-- 	end
		-- 	return {
		-- 		-- 2500ms ensures it doesn't fail silently on large files.
		-- 		timeout_ms = 2500,
		-- 		lsp_format = lsp_format_opt,
		-- 	}
		-- end,
		formatters_by_ft = {
			lua = { "stylua" },
			-- Conform will run multiple formatters sequentially
			python = { "isort", "black" },

			-- WEB DEVELOPMENT
			-- Use a sub-list to run only the first available formatter
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },

			-- Add css/html to the same logic
			css = { "prettierd", "prettier", stop_after_first = true },
			html = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
			markdown = { "prettierd", "prettier", stop_after_first = true },

			sh = { "shfmt" },
		},
	},
}
