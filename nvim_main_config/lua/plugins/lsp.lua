-- lua/plugins/lsp.lua
local safe = require("utils.safe")

return {
    -- CMP
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "rafamadriz/friendly-snippets",
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
        },
        config = function()
            local cmp = safe.require("cmp")
            if not cmp then return end

            local luasnip = safe.require("luasnip")
            if luasnip then
                safe.call(function()
                    require("luasnip.loaders.from_vscode").lazy_load()
                end)
            end

            local cmp_lsp = safe.require("cmp_nvim_lsp")
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            if cmp_lsp then
                capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
            end

            -- Guardamos capabilities para LSP (si ya está arrancado, no pasa nada)
            vim.g.__my_capabilities = capabilities

            cmp.setup({
                snippet = {
                    expand = function(args)
                        if luasnip then luasnip.lsp_expand(args.body) end
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
                    ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },

    -- Mason: solo instala binarios
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        config = function()
            local mason = safe.require("mason")
            if mason then mason.setup() end
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        event = "VeryLazy",
        config = function()
            local mason_lsp = safe.require("mason-lspconfig")
            if mason_lsp then
                mason_lsp.setup({
                    ensure_installed = {
                        "lua_ls",
                        "rust_analyzer",
                        "gopls",
                        "zls",
                        "pylsp",
                        "denols",
                        "ts_ls",
                        "intelephense",
                    },
                })
            end
        end,
    },

    -- LSP setup real
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "j-hui/fidget.nvim" },
        config = function()
            -- Fidget aquí (si lo quieres “pegado” al LSP)
            local fidget = safe.require("fidget")
            if fidget then fidget.setup({}) end

            require("config.lsp").setup()
        end,
    },
}
