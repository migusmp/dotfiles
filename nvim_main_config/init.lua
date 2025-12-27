-- ~/.config/nvim/init.lua

-- 1) Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- 2) Config base (sin plugins)
require("config.settings")
require("config.diagnostics")
require("config.keymaps")
require("config.autocmds")

-- 3) Plugins
require("lazy").setup({
    { import = "plugins.core" },
    { import = "plugins.ui" },
    { import = "plugins.lsp" },
    { import = "plugins.dev" },
}, {
    install = { colorscheme = { "rose-pine" } },
    checker = { enabled = true },
    change_detection = { notify = false },
})
