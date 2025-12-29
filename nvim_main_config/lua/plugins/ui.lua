-- lua/plugins/ui.lua
local safe = require("utils.safe")

local function transparent()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        priority = 1000,
        config = function()
            local rp = safe.require("rose-pine")
            if rp then
                rp.setup({ disable_background = true, styles = { italic = false } })
            end
            vim.cmd.colorscheme("rose-pine-moon")
            transparent()
        end,
    },
    -- Si quieres mantener “tema por lenguaje”, lo hacemos en autocmd y SIN duplicar 200 highlights
    {
        "morhetz/gruvbox",
        lazy = true,
        config = function()
            vim.g.gruvbox_contrast_dark = "soft"
            vim.g.gruvbox_italic = 0
        end,
    },
    {
        "olimorris/onedarkpro.nvim",
        lazy = true,
    },

    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local lualine = safe.require("lualine")
            if lualine then
                lualine.setup({ options = { theme = "auto", globalstatus = true } })
            end
        end,
    },

    {
        "terrortylor/nvim-comment",
        event = "VeryLazy",
        config = function()
            local c = safe.require("nvim_comment")
            if c then c.setup({ hook = function() end }) end
        end,
    },

    {
        "j-hui/fidget.nvim",
        event = "LspAttach",
        config = function()
            local f = safe.require("fidget")
            if f then f.setup({}) end
        end,
    },
    -- gitsigns.nvim
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("gitsigns").setup({
                signs = {
                    add          = { text = "│" },
                    change       = { text = "│" },
                    delete       = { text = "_" },
                    topdelete    = { text = "‾" },
                    changedelete = { text = "~" },
                },

                -- Muestra blame de la línea actual
                current_line_blame = true,
                current_line_blame_opts = {
                    delay = 500,
                },

                on_attach = function(_) end,
            })
        end,
    },
    -- oil.nvim (modern file explorer)
    {
        "stevearc/oil.nvim",
        lazy = false, -- ✅ necesario para que funcione con `nvim .`
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("oil").setup({
                default_file_explorer = true, -- ✅ Oil maneja directorios
                columns = { "icon", "permissions", "size" },
                view_options = { show_hidden = true },
                use_default_keymaps = true,
            })
        end,
    },
}
