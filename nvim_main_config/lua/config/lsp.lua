-- lua/config/lsp.lua
local M = {}

-- =========================
-- Helpers
-- =========================
local function root_pattern(...)
    local patterns = { ... }
    return function(bufnr)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local dir = vim.fs.dirname(fname)
        return vim.fs.root(dir, patterns)
    end
end

-- =========================
-- on_attach (keymaps por buffer)
-- =========================
local function on_attach(_, bufnr)
    local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, {
            buffer = bufnr,
            silent = true,
            desc = desc,
        })
    end

    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
end

-- =========================
-- LSP setup
-- =========================
function M.setup()
    ------------------------------------------------------------------
    -- 🔥 DETALLE PRO QUE FALTABA (ORDER-INDEPENDENT CAPABILITIES)
    ------------------------------------------------------------------
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- Si cmp_nvim_lsp está instalado, ampliamos capabilities
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok then
        capabilities = vim.tbl_deep_extend(
            "force",
            capabilities,
            cmp_lsp.default_capabilities()
        )
    end

    -- Guardamos por si algún otro módulo las necesita
    vim.g.__my_capabilities = capabilities
    ------------------------------------------------------------------

    -- =========================
    -- ZIG (zls)
    -- =========================
    vim.lsp.config("zls", {
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = root_pattern(".git", "build.zig", "zls.json"),
        settings = {
            zls = {
                enable_inlay_hints = true,
                enable_snippets = true,
                warn_style = true,
            },
        },
    })
    vim.g.zig_fmt_parse_errors = 0
    vim.g.zig_fmt_autosave = 0

    -- =========================
    -- LUA
    -- =========================
    vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
            Lua = {
                runtime = { version = "Lua 5.1" },
                diagnostics = {
                    globals = {
                        "vim",
                        "bit",
                        "it",
                        "describe",
                        "before_each",
                        "after_each",
                    },
                },
            },
        },
    })

    -- =========================
    -- RUST / GO
    -- =========================
    vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
        on_attach = on_attach,
    })

    vim.lsp.config("gopls", {
        capabilities = capabilities,
        on_attach = on_attach,
    })

    -- =========================
    -- ENABLE ALL
    -- =========================
    vim.lsp.enable({
        "lua_ls",
        "rust_analyzer",
        "gopls",
        "zls",
    })
end

return M
