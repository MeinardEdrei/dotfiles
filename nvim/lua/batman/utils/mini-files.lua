local M = {}
local image_cache = {}

M.setup = function(opts)
	local mini_files = require("mini.files")

	-- ============================================================
	-- PART 1: AUTOMATIC IMAGE PREVIEW
	-- ============================================================
	vim.api.nvim_create_autocmd("User", {
		pattern = "MiniFilesWindowUpdate",
		callback = function(args)
			local win_id = args.data.win_id
			local buf_id = args.data.buf_id

			-- 1. Sanitize the path
			local path = vim.api.nvim_buf_get_name(buf_id)
			if not path or path == "" then
				return
			end
			if path:match("^minifiles://") then
				path = path:match("^minifiles://%d+/(.+)$")
			end
			if not path or not vim.loop.fs_stat(path) then
				return
			end

			local ext = vim.fn.fnamemodify(path, ":e"):lower()
			local img_extensions = { "png", "jpg", "jpeg", "webp", "gif", "avif", "svg", "ico" }

			if vim.tbl_contains(img_extensions, ext) then
				-- 2. CLEANUP: Close previous image for this window immediately
				if image_cache[win_id] then
					pcall(function()
						image_cache[win_id]:close()
					end)
					image_cache[win_id] = nil
				end

				-- 3. PREPARE BUFFER (Recursive Safe)
				-- We pad the buffer immediately so it's ready for the image
				if vim.api.nvim_buf_line_count(buf_id) < 10 then
					vim.bo[buf_id].modifiable = true
					local filler = {}
					for i = 1, 100 do
						table.insert(filler, "")
					end
					vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, filler)
					return -- Stop here, let recursion handle the redraw
				end

				-- 4. PREPARE WINDOW
				vim.api.nvim_win_set_option(win_id, "wrap", false)
				vim.api.nvim_win_set_option(win_id, "signcolumn", "no")
				vim.api.nvim_win_set_option(win_id, "number", false)
				vim.api.nvim_win_set_option(win_id, "relativenumber", false)
				vim.api.nvim_win_set_option(win_id, "cursorline", false)

				-- 5. RENDER (Single-Shot Delayed)
				if package.loaded["snacks"] then
					-- We wait 40ms. This allows the mini.files window animation to finish.
					-- Then we calculate the size and draw ONCE. No updates, no flicker.
					vim.defer_fn(function()
						if not vim.api.nvim_win_is_valid(win_id) then
							return
						end

						-- Check if we are still looking at the same buffer
						if vim.api.nvim_win_get_buf(win_id) ~= buf_id then
							return
						end

						local w = vim.api.nvim_win_get_width(win_id)
						local h = vim.api.nvim_win_get_height(win_id)
						local img = nil

						if Snacks.image.new then
							img = Snacks.image.new(path)
							img:mount({ buf = buf_id, win = win_id, width = w, height = h, fit = "contain" })
						elseif Snacks.image.placement then
							img = Snacks.image.placement.new(buf_id, path, {
								inline = false,
								width = w,
								height = h,
								x = 0,
								y = 0,
							})
							if img then
								img:update()
							end
						else
							Snacks.image.hover(path)
						end

						if img then
							image_cache[win_id] = img
							vim.cmd("redraw")
						end
					end, 40) -- 40ms delay (Adjust to 60 if still flickering)
				end
			end
		end,
	})

	-- ============================================================
	-- PART 2: CUSTOM KEYMAPS (Keep your existing keymaps)
	-- ============================================================
	vim.api.nvim_create_autocmd("User", {
		pattern = "MiniFilesBufferCreate",
		callback = function(args)
			local buf_id = args.data.buf_id
			local keymaps = opts.custom_keymaps or {}

			-- 1. Open in Tmux Pane
			vim.keymap.set("n", keymaps.open_tmux_pane, function()
				local curr_entry = mini_files.get_fs_entry()
				if curr_entry and curr_entry.fs_type == "directory" then
					require("config.keymaps").tmux_pane_function(curr_entry.path)
				else
					vim.notify("Not a directory", vim.log.levels.WARN)
				end
			end, { buffer = buf_id, noremap = true, silent = true })

			-- 2. Copy to Clipboard (macOS)
			vim.keymap.set("n", keymaps.copy_to_clipboard, function()
				local curr_entry = mini_files.get_fs_entry()
				if curr_entry then
					local path = curr_entry.path
					local cmd = string.format([[osascript -e 'set the clipboard to POSIX file "%s"' ]], path)
					if vim.fn.system(cmd) then
						vim.notify(vim.fn.fnamemodify(path, ":t") .. " copied to clipboard", vim.log.levels.INFO)
					end
				end
			end, { buffer = buf_id, noremap = true, silent = true, desc = "[P]Copy to clipboard" })

			-- 3. Zip and Copy
			vim.keymap.set("n", keymaps.zip_and_copy, function()
				local curr_entry = mini_files.get_fs_entry()
				if curr_entry then
					local path = curr_entry.path
					local name = vim.fn.fnamemodify(path, ":t")
					local parent_dir = vim.fn.fnamemodify(path, ":h")
					local timestamp = os.date("%y%m%d%H%M%S")
					local zip_path = string.format("/tmp/%s_%s.zip", name, timestamp)
					local zip_cmd = string.format(
						"cd %s && zip -r %s %s",
						vim.fn.shellescape(parent_dir),
						vim.fn.shellescape(zip_path),
						vim.fn.shellescape(name)
					)

					vim.fn.system(zip_cmd)
					local copy_cmd = string.format(
						[[osascript -e 'set the clipboard to POSIX file "%s"' ]],
						vim.fn.fnameescape(zip_path)
					)
					vim.fn.system(copy_cmd)
					vim.notify("Zipped and copied: " .. zip_path, vim.log.levels.INFO)
				end
			end, { buffer = buf_id, noremap = true, silent = true, desc = "[P]Zip and copy" })

			-- 4. Paste from Clipboard
			vim.keymap.set("n", keymaps.paste_from_clipboard, function()
				local curr_entry = mini_files.get_fs_entry()
				if not curr_entry then
					return
				end
				local curr_dir = curr_entry.fs_type == "directory" and curr_entry.path
					or vim.fn.fnamemodify(curr_entry.path, ":h")
				local script = [[tell application "System Events" to return POSIX path of (the clipboard as alias)]]
				local output = vim.fn.system("osascript -e " .. vim.fn.shellescape(script))

				if vim.v.shell_error == 0 then
					local source_path = output:gsub("%s+$", "")
					local dest_path = curr_dir .. "/" .. vim.fn.fnamemodify(source_path, ":t")
					local cmd = vim.fn.isdirectory(source_path) == 1 and { "cp", "-R", source_path, dest_path }
						or { "cp", source_path, dest_path }
					vim.fn.system(cmd)
					mini_files.synchronize()
					vim.notify("Pasted successfully", vim.log.levels.INFO)
				else
					vim.notify("Clipboard invalid", vim.log.levels.WARN)
				end
			end, { buffer = buf_id, noremap = true, silent = true, desc = "[P]Paste from clipboard" })

			-- 5. Copy Path Relative
			vim.keymap.set("n", keymaps.copy_path, function()
				local curr_entry = mini_files.get_fs_entry()
				if curr_entry then
					local relative_path = curr_entry.path:gsub("^" .. vim.fn.expand("~"), "~")
					vim.fn.setreg("+", relative_path)
					vim.notify("Path copied: " .. relative_path, vim.log.levels.INFO)
				end
			end, { buffer = buf_id, noremap = true, silent = true, desc = "[P]Copy relative path" })

			-- 6. Preview Image (QuickLook macOS)
			vim.keymap.set("n", keymaps.preview_image, function()
				local curr_entry = mini_files.get_fs_entry()
				if curr_entry then
					vim.system({ "qlmanage", "-p", curr_entry.path }, { stdout = false, stderr = false })
					vim.defer_fn(function()
						vim.system({ "osascript", "-e", 'tell application "qlmanage" to activate' })
					end, 200)
				end
			end, { buffer = buf_id, noremap = true, silent = true, desc = "[P]Preview macOS QuickLook" })

			-- 7. PREVIEW IMAGE POPUP (Manual Zoom)
			vim.keymap.set("n", keymaps.preview_image_popup, function()
				local curr_entry = mini_files.get_fs_entry()
				if curr_entry and curr_entry.fs_type == "file" then
					if package.loaded["snacks"] then
						-- Fallback to hover since it's universally available
						Snacks.image.hover(curr_entry.path)
					else
						vim.notify("Snacks.nvim not installed", vim.log.levels.ERROR)
					end
				end
			end, { buffer = buf_id, noremap = true, silent = true, desc = "[P]Zoom Image" })
		end,
	})
end

return M
