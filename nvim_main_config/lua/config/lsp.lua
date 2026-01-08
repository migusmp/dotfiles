-- lua/config/lsp.lua
local M = {}

local function clangd_cmd()
    local mason_clangd = vim.fn.stdpath("data") .. "/mason/bin/clangd"
    if vim.fn.executable(mason_clangd) == 1 then
        return { mason_clangd }
    end
    return { "clangd" }
end


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

    map("n", "<leader>gg", vim.lsp.buf.hover, "Hover (info símbolo)")
    map("n", "<leader>gi", vim.lsp.buf.implementation, "Ir a implementación")
    map("n", "<leader>gt", vim.lsp.buf.type_definition, "Type definition")
    map("n", "<leader>gr", vim.lsp.buf.references, "References")
    map("n", "<leader>gs", vim.lsp.buf.signature_help, "Signature help")
    map("n", "<leader>rr", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>ga", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>gl", vim.diagnostic.open_float, "Diagnostic float")
    map("n", "<leader>gp", vim.diagnostic.goto_prev, "Prev diagnostic")
    map("n", "<leader>gn", vim.diagnostic.goto_next, "Next diagnostic")
    map("n", "<leader>tr", vim.lsp.buf.document_symbol, "Document symbols")
    map("i", "<c-space>", vim.lsp.buf.completion, "Completion")
end

M._on_attach = on_attach

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
    -- PHP (intelephense)
    -- =========================
    vim.lsp.config("intelephense", {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/intelephense", "--stdio" },
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = root_pattern("composer.json", ".git"),
    })

    -- =========================
    -- ASM (asm-lsp) - NASM/GAS
    -- =========================
    vim.lsp.config("asm_lsp", {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/asm-lsp" },
        capabilities = capabilities,
        on_attach = function(client, bufnr)
            -- Apaga diagnostics SOLO para asm_lsp (sin afectar a otros LSP)
            client.handlers["textDocument/publishDiagnostics"] = function() end

            on_attach(client, bufnr)
        end,
        root_dir = function(bufnr)
            local root = root_pattern(".asm-lsp.toml", ".git")(bufnr)
            if root then return root end
            local fname = vim.api.nvim_buf_get_name(bufnr)
            if fname == "" then return vim.loop.cwd() end
            return vim.fs.dirname(fname)
        end,
        single_file_support = true,
        filetypes = { "asm" },
    })

    -- =========================
    -- C / C++ (clangd) - config
    -- =========================

    vim.lsp.config("clangd", {
        capabilities = vim.g.__my_capabilities,
        on_attach = M._on_attach,
        cmd = clangd_cmd(),
        root_dir = root_pattern(".git", "compile_commands.json", "Makefile", "CMakeLists.txt"),
        single_file_support = true,
        filetypes = { "c", "cpp", "objc", "objcpp" },
    })

    -- =========================
    -- ENABLE ALL
    -- =========================
    vim.lsp.enable({
        "lua_ls",
        "rust_analyzer",
        "gopls",
        "zls",
        "intelephense",
        "clangd",
        -- "asm_lsp",
    })
end

-- =========================
-- Force start asm_lsp on asm buffers (because vim.lsp.enable may not autostart it)
-- =========================
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "asm" },
    callback = function(args)
        -- si ya hay un asm_lsp en el buffer, no hagas nada
        if #vim.lsp.get_clients({ bufnr = args.buf, name = "asm_lsp" }) > 0 then
            return
        end

        local fname = vim.api.nvim_buf_get_name(args.buf)
        local dir = vim.fs.dirname(fname)

        vim.lsp.start({
            name = "asm_lsp",
            cmd = { vim.fn.stdpath("data") .. "/mason/bin/asm-lsp" },
            root_dir = vim.fs.root(dir, { ".asm-lsp.toml", ".git" }) or dir,
            capabilities = vim.g.__my_capabilities or capabilities,
            on_attach = function(client, bufnr)
                -- apagar diagnostics falsos sí o sí
                client.handlers["textDocument/publishDiagnostics"] = function() end
                on_attach(client, bufnr)
            end,
        })
    end,
})

-- =========================
-- clangd autostart (FileType)
-- =========================
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "objc", "objcpp" },
    callback = function(args)
        if #vim.lsp.get_clients({ bufnr = args.buf, name = "clangd" }) > 0 then
            return
        end

        local fname = vim.api.nvim_buf_get_name(args.buf)
        local dir = vim.fs.dirname(fname)
        local root = vim.fs.root(dir, { ".git", "compile_commands.json", "Makefile", "CMakeLists.txt" }) or dir

        vim.lsp.start({
            name = "clangd",
            cmd = clangd_cmd(),
            root_dir = root,
            capabilities = vim.g.__my_capabilities,
            on_attach = M._on_attach,
        })
    end,
})

return M
