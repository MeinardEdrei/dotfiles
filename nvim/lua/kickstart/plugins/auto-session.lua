return {
  "rmagatti/auto-session",
  lazy = false,
  keys = {
    {
      "<leader>fs",
      function() vim.cmd("AutoSession search") end,
      desc = "[F]ind [S]ession",
    },
  },
  opts = {
    log_level = "error",
    root_dir = vim.fn.stdpath("data") .. "/sessions/",
    auto_save = true,
    auto_restore = true,
    auto_create = true,
    suppressed_dirs = { "~/", "/tmp", "/", "~/Downloads", "~/Documents" },
    close_unsupported_windows = true,
    pre_save_cmds = {
      function()
        local ok, MiniFiles = pcall(require, "mini.files")
        if ok and MiniFiles then MiniFiles.close() end
      end,
    },
    session_lens = { previewer = false },
    bypass_session_save_file_types = { "gitcommit", "fugitive" },
    args_allow_single_directory = true,
  },
}
