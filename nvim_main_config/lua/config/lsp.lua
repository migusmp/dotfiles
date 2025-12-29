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

    map("n", "gd", function()
        -- ✅ encoding del cliente LSP del buffer
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        local enc = (clients[1] and clients[1].offset_encoding) or "utf-16"

        -- ✅ en Neovim nuevo hay que pasarlo aquí
        local params = vim.lsp.util.make_position_params(0, enc)

        vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result)
            if err or not result then return end

            local locations = vim.islist(result) and result or { result }

            -- Deduplicar por uri + rango
            local seen, uniq = {}, {}
            for _, loc in ipairs(locations) do
                local uri = loc.uri or loc.targetUri
                local range = loc.range or loc.targetSelectionRange or loc.targetRange
                if uri and range then
                    local key = string.format(
                        "%s:%d:%d:%d:%d",
                        uri,
                        range.start.line, range.start.character,
                        range["end"].line, range["end"].character
                    )
                    if not seen[key] then
                        seen[key] = true
                        table.insert(uniq, loc)
                    end
                end
            end

            if #uniq == 0 then return end

            if #uniq == 1 then
                vim.lsp.util.show_document(uniq[1], enc, { focus = true })
            else
                require("telescope.builtin").lsp_definitions()
            end
        end)
    end, "Go to definition (dedup)")

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
