-- lua/plugins/core.lua
local safe = require("utils.safe")

return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            local ok, configs = pcall(require, "nvim-treesitter.configs")
            if not ok then
                -- No spamear warnings: simplemente salimos
                return
            end

            configs.setup({
                ensure_installed = {
                    "vimdoc", "lua", "bash", "c", "cpp", "rust", "zig", "java",
                    "javascript", "typescript", "jsdoc", "php",
                },
                auto_install = true,
                highlight = { enable = true },
                indent = { enable = true },
            })

            -- Custom templ parser
            local okp, parsers = pcall(require, "nvim-treesitter.parsers")
            if okp then
                local cfg = parsers.get_parser_configs()
                cfg.templ = {
                    install_info = {
                        url = "https://github.com/vrischmann/tree-sitter-templ.git",
                        files = { "src/parser.c", "src/scanner.c" },
                        branch = "master",
                    },
                }
                pcall(vim.treesitter.language.register, "templ", "templ")
            end
        end,
    },

    { "nvim-lua/plenary.nvim", lazy = true },

    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = safe.require("telescope")
            if telescope then telescope.setup({}) end

            -- Keymaps aquí, para que solo existan si telescope está
            vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { silent = true, desc = "Find files" })
            vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { silent = true, desc = "Live grep" })
        end,
    },
}
