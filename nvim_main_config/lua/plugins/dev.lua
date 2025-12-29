-- lua/plugins/dev.lua
local safe = require("utils.safe")

return {
    -- Format
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        config = function()
            local conform = safe.require("conform")
            if not conform then return end

            conform.setup({
                formatters_by_ft = {
                    cpp = { "clang_format" },
                    php = { "php_cs_fixer" },
                },
                format_on_save = {
                    timeout_ms = 500,
                    lsp_fallback = true,
                },
                formatters = {
                    php_cs_fixer = {
                        command = "php-cs-fixer",
                        args = { "fix", "$FILENAME" },
                        cwd = require("conform.util").root_file({
                            ".php-cs-fixer.php",
                            ".php-cs-fixer.dist.php",
                            "composer.json",
                            ".git",
                        }),
                    },
                },
            })

            vim.keymap.set("n", "<leader>f", function()
                conform.format({ lsp_fallback = true, timeout_ms = 1000 })
            end, { desc = "Format file", silent = true })
        end,
    },

    -- Harpoon
    {
        "ThePrimeagen/harpoon",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- Autopairs
    { "windwp/nvim-autopairs",  event = "InsertEnter", config = function() require("nvim-autopairs").setup({}) end },

    -- Multi-cursor
    { "mg979/vim-visual-multi", branch = "master" },

    -- Rust
    { "rust-lang/rust.vim",     ft = "rust",           init = function() vim.g.rustfmt_autosave = 1 end },
    { "mrcjkb/rustaceanvim",    version = "^5",        ft = { "rust" } },

    -- crates.nvim
    {
        "saecki/crates.nvim",
        ft = { "toml" },
        config = function()
            local crates = safe.require("crates")
            if crates then crates.setup({ completion = { cmp = { enabled = true } } }) end
        end,
    },

    -- tmux integration
    {
        "aserowy/tmux.nvim",
        event = "VeryLazy",
        config = function()
            local tmux = safe.require("tmux")
            if tmux then
                tmux.setup({
                    copy_sync = { enable = true, sync_clipboard = true, sync_registers = true },
                    navigation = { cycle_navigation = true, enable_default_keybindings = true },
                    resize = { enable_default_keybindings = true },
                })
            end
        end,
    },

    -- codeium
    { "Exafunction/codeium.vim", event = "BufEnter" },
}
