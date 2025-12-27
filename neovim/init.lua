-- ~/.config/nvim/init.lua
-- Neovim 0.11+ (sin warnings de lspconfig deprecated)
-- Mantiene tu setup, pero:
--  - NO usa mason-lspconfig handlers
--  - Usa vim.lsp.config + vim.lsp.enable (nuevo API)
--  dsadada
--  - Evita el bug de "mod boolean"
--  - Quita duplicados (cmp / conform / diagnostics / intelephense)

-- =========================
-- Colorscheme helper
-- =========================
function ColorMyPencils(color)
    color = color or "rose-pine-moon"
    vim.cmd.colorscheme(color)
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

-- =========================
-- Lazy.nvim bootstrap
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

-- =========================
-- Helpers (para que NO pete el init)
-- =========================
local function safe_require(mod)
    local ok, m = pcall(require, mod)
    if not ok then return nil end
    -- algunos módulos devuelven boolean => evita "attempt to index local 'mod' (a boolean value)"
    if type(m) == "boolean" then return nil end
    return m
end

local function safe_call(fn)
    local ok, err = pcall(fn)
    if not ok then
        vim.schedule(function()
            vim.notify(err, vim.log.levels.ERROR)
        end)
    end
end

-- =========================
-- Plugins
-- =========================
require("lazy").setup({
    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local ok, configs = pcall(require, "nvim-treesitter.configs")
            if not ok then
                vim.schedule(function()
                    vim.notify("Treesitter aún no está instalado. Ejecuta :Lazy sync", vim.log.levels.WARN)
                end)
                return
            end

            configs.setup({
                ensure_installed = {
                    "vimdoc", "javascript", "typescript", "c", "lua", "rust",
                    "jsdoc", "bash", "cpp", "java", "zig", "nasm", "asm", "php",
                },
                sync_install = false,
                auto_install = true,
                indent = { enable = true },
                highlight = { enable = true, additional_vim_regex_highlighting = false },
            })

            local ok_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
            if ok_parsers then
                local treesitter_parser_config = parsers.get_parser_configs()
                treesitter_parser_config.templ = {
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

    -- Telescope
    { "nvim-telescope/telescope.nvim",    dependencies = { "nvim-lua/plenary.nvim" } },

    -- CMP + snippets
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "saadparwaiz1/cmp_luasnip",
        },
    },
    { "L3MON4D3/LuaSnip" },
    { "rafamadriz/friendly-snippets" },

    -- LSP plumbing (lo dejamos instalado, pero NO lo usamos para setup)
    { "neovim/nvim-lspconfig" },

    -- Tools
    { "stevearc/conform.nvim" },
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "j-hui/fidget.nvim" },

    -- Themes
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            require("rose-pine").setup({
                disable_background = true,
                styles = { italic = false },
            })
            ColorMyPencils()
        end,
    },

    {
        "morhetz/gruvbox",
        config = function()
            vim.g.gruvbox_contrast_dark = "soft"
            vim.g.gruvbox_italic = 0
            vim.g.gruvbox_transparent_bg = 1

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "c", "cpp" },
                callback = function()
                    vim.cmd("colorscheme gruvbox")
                    vim.cmd("highlight Function guifg=#D4C4A8 ctermfg=223")
                    vim.cmd("highlight Function guifg=#E0D6B4 ctermfg=223")
                    vim.cmd("highlight Normal guibg=none")
                    vim.cmd("highlight NonText guibg=none")
                    vim.cmd("highlight NormalNC guibg=none")
                    vim.cmd("highlight VertSplit guibg=none")
                    vim.cmd("highlight SignColumn guibg=none")
                    vim.cmd("highlight LineNr guibg=none")
                    vim.cmd("highlight CursorLineNr guibg=none")
                    vim.cmd("highlight StatusLine guibg=none")
                    vim.cmd("highlight StatusLineNC guibg=none")
                end,
            })
        end,
    },

    {
        "olimorris/onedarkpro.nvim",
        config = function()
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                callback = function()
                    vim.cmd("colorscheme onedark_dark")
                    vim.cmd("highlight Normal guibg=none")
                    vim.cmd("highlight NonText guibg=none")
                    vim.cmd("highlight NormalNC guibg=none")
                    vim.cmd("highlight VertSplit guibg=none")
                    vim.cmd("highlight SignColumn guibg=none")
                    vim.cmd("highlight LineNr guibg=none")
                    vim.cmd("highlight CursorLineNr guibg=none")
                    vim.cmd("highlight StatusLine guibg=none")
                    vim.cmd("highlight StatusLineNC guibg=none")
                end,
            })
        end,
    },

    -- Harpoon
    {
        "ThePrimeagen/harpoon",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            vim.keymap.set("n", "<leader>ha", ':lua require("harpoon.mark").add_file()<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "<Leader>h", ':lua require("harpoon.ui").toggle_quick_menu()<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "<Leader>1", ':lua require("harpoon.ui").nav_file(1)<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "<Leader>2", ':lua require("harpoon.ui").nav_file(2)<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "<Leader>3", ':lua require("harpoon.ui").nav_file(3)<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "<Leader>4", ':lua require("harpoon.ui").nav_file(4)<CR>',
                { noremap = true, silent = true })
        end,
    },

    -- Autopairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({})
        end,
    },

    -- Lualine
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({ options = { theme = "horizon" } })
        end,
    },

    -- Comments
    {
        "terrortylor/nvim-comment",
        config = function()
            require("nvim_comment").setup({
                hook = function() end,
            })
        end,
    },

    -- Multi-cursor
    { "mg979/vim-visual-multi", branch = "master" },

    -- Rust
    {
        "rust-lang/rust.vim",
        ft = "rust",
        init = function()
            vim.g.rustfmt_autosave = 1
        end,
    },
    { "mrcjkb/rustaceanvim",    version = "^5",   ft = { "rust" } },

    -- crates.nvim
    {
        "saecki/crates.nvim",
        ft = { "toml" },
        config = function()
            require("crates").setup({
                completion = { cmp = { enabled = true } },
            })
            local cmp = safe_require("cmp")
            if cmp then
                require("cmp").setup.buffer({ sources = { { name = "crates" } } })
            end
        end,
    },

    -- tmux.nvim
    {
        "aserowy/tmux.nvim",
        config = function()
            return require("tmux").setup({
                copy_sync = {
                    enable = true,
                    ignore_buffers = { empty = false },
                    redirect_to_clipboard = false,
                    register_offset = 0,
                    sync_clipboard = true,
                    sync_registers = true,
                    sync_registers_keymap_put = true,
                    sync_registers_keymap_reg = true,
                    sync_deletes = true,
                    sync_unnamed = true,
                },
                navigation = {
                    cycle_navigation = true,
                    enable_default_keybindings = true,
                    persist_zoom = false,
                },
                resize = {
                    enable_default_keybindings = true,
                    resize_step_x = 1,
                    resize_step_y = 1,
                },
            })
        end,
    },

    -- codeium
    { "Exafunction/codeium.vim", event = "BufEnter" },
})

-- =========================
-- Diagnostics (una sola vez)
-- =========================
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
    },
})

-- =========================
-- Fidget
-- =========================
safe_call(function()
    local fidget = safe_require("fidget")
    if fidget then fidget.setup({}) end
end)

-- =========================
-- Mason (solo instala binarios)
-- =========================
safe_call(function()
    local mason = safe_require("mason")
    if mason then mason.setup() end

    local mason_lsp = safe_require("mason-lspconfig")
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
            -- IMPORTANTÍSIMO: NO handlers (handlers usa require("lspconfig") y da warning)
        })
    end
end)

-- =========================
-- CMP
-- =========================
safe_call(function()
    local cmp = safe_require("cmp")
    if not cmp then return end

    local luasnip = safe_require("luasnip")
    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    local cmp_lsp = safe_require("cmp_nvim_lsp")
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    if cmp_lsp then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
    end

    cmp.setup({
        snippet = {
            expand = function(args)
                if luasnip then luasnip.lsp_expand(args.body) end
            end,
        },
        mapping = cmp.mapping.preset.insert({
            ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
            ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
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

    -- guardamos capabilities para LSP
    vim.g.__my_capabilities = capabilities
end)

-- =========================
-- LSP (Neovim 0.11+): vim.lsp.config + vim.lsp.enable
-- =========================
safe_call(function()
    local capabilities = vim.g.__my_capabilities or vim.lsp.protocol.make_client_capabilities()

    local function on_attach(_, bufnr)
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
    end

    local function root_pattern(...)
        local patterns = { ... }
        return function(bufnr)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local dir = vim.fs.dirname(fname)
            return vim.fs.root(dir, patterns)
        end
    end

    -- lua
    vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
            Lua = {
                runtime = { version = "Lua 5.1" },
                diagnostics = { globals = { "vim", "bit", "it", "describe", "before_each", "after_each" } },
            },
        },
    })

    -- rust
    vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
        on_attach = on_attach,
    })

    -- go
    vim.lsp.config("gopls", {
        capabilities = capabilities,
        on_attach = on_attach,
    })

    -- zig
    vim.lsp.config("zls", {
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = root_pattern(".git", "build.zig", "zls.json"),
        settings = {
            zls = {
                enable_inlay_hints = true,
                enable_snippets = true,
                warn_style = true,
                enable_ast_check_diagnostics = true,
                enable_syntax_errors = true,
            },
        },
    })
    vim.g.zig_fmt_parse_errors = 0
    vim.g.zig_fmt_autosave = 0

    -- python
    vim.lsp.config("pylsp", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
            pylsp = {
                plugins = {
                    pyflakes = { enabled = false },
                    pycodestyle = { enabled = false },
                    pylint = { enabled = true },
                    black = { enabled = true },
                    isort = { enabled = true },
                },
            },
        },
    })

    -- deno
    vim.lsp.config("denols", {
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = root_pattern("deno.json", "deno.jsonc"),
    })

    -- ts
    vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = root_pattern("package.json"),
        single_file_support = false,
    })

    -- php: intelephense
    vim.lsp.config("intelephense", {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
            on_attach(client, bufnr)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
        end,
        root_dir = root_pattern("composer.json", ".git", "index.php"),
        init_options = { licenceKey = nil },
        settings = {
            intelephense = {
                files = { maxSize = 5000000 },
                stubs = {
                    "apache", "bcmath", "bz2", "calendar", "core", "curl",
                    "date", "dom", "fileinfo", "filter", "gd", "gettext",
                    "hash", "iconv", "imap", "intl", "json", "ldap", "mbstring",
                    "mysqli", "password", "pcre", "PDO", "pdo_mysql", "Phar",
                    "posix", "readline", "Reflection", "session", "SimpleXML",
                    "sockets", "sodium", "SPL", "sqlite3", "standard",
                    "superglobals", "tokenizer", "xml", "zip",
                },
            },
        },
    })

    -- Enable all
    vim.lsp.enable({
        "lua_ls",
        "rust_analyzer",
        "gopls",
        "zls",
        "pylsp",
        "denols",
        "ts_ls",
        "intelephense",
    })
end)

-- =========================
-- Conform (una sola vez)
-- =========================
safe_call(function()
    local conform = safe_require("conform")
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
end)

-- =========================
-- Java snippets + command (solo si luasnip existe)
-- =========================
safe_call(function()
    local ls = safe_require("luasnip")
    if not ls then return end

    local s = ls.snippet
    local t = ls.text_node
    local i = ls.insert_node
    local d = ls.dynamic_node
    local sn = ls.snippet_node

    local function toCamelCase(args)
        local var_name = args[1][1] or ""
        if var_name == "" then return sn(nil, { t("") }) end
        return sn(nil, { t(var_name:sub(1, 1):upper() .. var_name:sub(2)) })
    end

    ls.add_snippets("java", {
        s("getset", {
            t("public "), i(1, "Tipo"), t(" get"),
            d(2, toCamelCase, { 3 }), t("() { return this."),
            i(3, "variable"), t("; }"),
            t({ "", "public void set" }),
            d(4, toCamelCase, { 3 }), t("("),
            i(1), t(" "), i(3), t(") { this."),
            i(3), t(" = "), i(3), t("; }"),
        }),
    })

    local function generate_getter_setter()
        local var_line = vim.api.nvim_get_current_line()
        local var_type, var_name = var_line:match("private%s+(%w+)%s+(%w+);")
        if not var_type or not var_name then
            print("No se encontró una variable privada en la línea actual.")
            return
        end

        local camel = var_name:sub(1, 1):upper() .. var_name:sub(2)
        local getter = string.format("public %s get%s() { return this.%s; }", var_type, camel, var_name)
        local setter = string.format("public void set%s(%s %s) { this.%s = %s; }", camel, var_type, var_name, var_name,
            var_name)

        local row = vim.api.nvim_win_get_cursor(0)[1]
        vim.api.nvim_buf_set_lines(0, row, row, false, { getter, setter })
    end

    vim.api.nvim_create_user_command("GenGetSet", generate_getter_setter, {})
end)

-- =========================
-- Cargar módulos extra (SIN romper inicio)
-- =========================
for _, m in ipairs({ "keymaps", "lsp", "telescope", "settings", "colors", "treesitter" }) do
    safe_call(function()
        local mod = safe_require(m)
        if type(mod) == "table" and type(mod.setup) == "function" then
            mod.setup()
        end
    end)
end
