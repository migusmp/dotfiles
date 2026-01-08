-- lua/config/autocmds.lua
-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank({ timeout = 120 })
    end,
})

-- =========================
-- Tema por lenguaje (C/C++)
-- =========================
local aug = vim.api.nvim_create_augroup("LangColorscheme", { clear = true })

local function load_and_set(scheme, plugin)
    local ok_lazy, lazy = pcall(require, "lazy")
    if ok_lazy and plugin then
        pcall(lazy.load, { plugins = { plugin } })
    end
    pcall(vim.cmd.colorscheme, scheme)
end

local function normalize_c_highlights()
    local white = "#ebdbb2" -- blanco gruvbox

    -- 1. Funciones en blanco (main, printf, etc.)
    vim.api.nvim_set_hl(0, "Function", {
        fg = white,
        bold = false,
        italic = false,
    })

    -- 2. Identificadores (variables) en blanco
    vim.api.nvim_set_hl(0, "Identifier", {
        fg = white,
        bold = false,
        italic = false,
    })

    -- 3. Strings → verde Gruvbox ORIGINAL
    vim.api.nvim_set_hl(0, "String", {
        fg = "#b8bb26", -- verde gruvbox
        bold = false,
        italic = false,
    })

    -- 4. Bucles, if, return → rojo Gruvbox ORIGINAL
    vim.api.nvim_set_hl(0, "Keyword", {
        fg = "#fb4934", -- rojo gruvbox
        bold = false,
        italic = false,
    })
    vim.api.nvim_set_hl(0, "Statement", {
        fg = "#fb4934",
        bold = false,
        italic = false,
    })

    -- 5. Tipos (int, char, void) → blanco
    vim.api.nvim_set_hl(0, "Type", {
        fg = white,
        bold = false,
        italic = false,
    })

    -- 6. Preprocesador (#include) → rojo suave (default)
    vim.api.nvim_set_hl(0, "PreProc", {
        fg = "#fb4934",
        bold = false,
        italic = false,
    })
    vim.api.nvim_set_hl(0, "Include", {
        fg = "#fb4934",
        bold = false,
        italic = false,
    })

    -- =========================
    -- Structs en amarillo Gruvbox
    -- =========================

    -- Syntax clásico
    vim.api.nvim_set_hl(0, "Structure", {
        fg = "#fabd2f",
        bold = false,
        italic = false,
    })

    -- Tipo general (struct Foo)
    vim.api.nvim_set_hl(0, "Type", {
        fg = "#fabd2f",
        bold = false,
        italic = false,
    })

    -- Tree-sitter (clave)
    vim.api.nvim_set_hl(0, "@type", {
        fg = "#fabd2f",
        bold = false,
        italic = false,
    })

    vim.api.nvim_set_hl(0, "@type.definition", {
        fg = "#fabd2f",
        bold = false,
        italic = false,
    })

    vim.api.nvim_set_hl(0, "@type.builtin", {
        fg = "#fabd2f",
        bold = false,
        italic = false,
    })

    vim.api.nvim_set_hl(0, "@structure", {
        fg = "#fabd2f",
        bold = false,
        italic = false,
    })
end

local function set_pretty_selection_for_gruvbox()
    -- Para fondo gruvbox dark soft
    local sel_bg = "#3c3836" -- gris oscuro suave (selection)
    local float_bg = "#1d2021"

    -- Selección normal
    vim.api.nvim_set_hl(0, "Visual", { bg = sel_bg, fg = "NONE", bold = false, italic = false, reverse = false })
    vim.api.nvim_set_hl(0, "VisualNOS", { bg = sel_bg, fg = "NONE", bold = false, italic = false, reverse = false })

    -- Evita los amarillos/naranjas feos de búsqueda
    vim.api.nvim_set_hl(0, "Search", { bg = "#504945", fg = "NONE" })
    vim.api.nvim_set_hl(0, "IncSearch", { bg = "#665c54", fg = "NONE" })
    vim.api.nvim_set_hl(0, "CurSearch", { bg = "#665c54", fg = "NONE" })

    -- Bordes de floats consistentes
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = float_bg })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = float_bg })
end

local function set_gruvbox_bg()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
    vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
    vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none", fg = "none" })
end

local function set_transparent()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
    vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
    vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none" })
end

local function soften_visual_selection()
    vim.api.nvim_set_hl(0, "Visual", {
        bg = "#3a3a3a", -- gris oscuro suave (no rosa)
        fg = "NONE",
        bold = false,
        italic = false,
        reverse = false,
    })

    vim.api.nvim_set_hl(0, "VisualNOS", {
        bg = "#3a3a3a",
        fg = "NONE",
    })
end

local function soften_type_colors()
    -- Gris suave estilo gruvbox
    local gray = "#a89984"

    -- Highlight clásico
    vim.api.nvim_set_hl(0, "Type", {
        fg = gray,
        italic = true,
    })

    vim.api.nvim_set_hl(0, "StorageClass", {
        fg = gray,
        italic = true,
    })

    -- Tree-sitter (MUY IMPORTANTE)
    vim.api.nvim_set_hl(0, "@type", {
        fg = gray,
        italic = true,
    })

    vim.api.nvim_set_hl(0, "@type.builtin", {
        fg = gray,
        italic = true,
    })

    vim.api.nvim_set_hl(0, "@type.definition", {
        fg = gray,
        italic = true,
    })
end

local function disable_italics()
    -- Lista típica de grupos que suelen ir en cursiva
    local groups = {
        "Comment",
        "Keyword",
        "Conditional",
        "Repeat",
        "Statement",
        "Type",
        "StorageClass",
        "Function",
        "Identifier",
        "Special",
        "PreProc",
        "Include",
        "Define",
        "Macro",
        "Exception",
        "Operator",
    }

    for _, g in ipairs(groups) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
        if ok then
            hl.italic = false
            vim.api.nvim_set_hl(0, g, hl)
        end
    end

    -- Treesitter (muchas themes ponen cursiva aquí)
    local ts_groups = {
        "@comment",
        "@keyword",
        "@keyword.function",
        "@keyword.return",
        "@type",
        "@type.builtin",
        "@storageclass",
        "@function",
        "@function.builtin",
        "@variable",
        "@parameter",
    }

    for _, g in ipairs(ts_groups) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
        if ok then
            hl.italic = false
            vim.api.nvim_set_hl(0, g, hl)
        end
    end
end

-- Se reaplica cada vez que cambias colorscheme
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        disable_italics()
    end,
})

-- evita recalcular y evita “parpadeos”
local current = nil
local function apply()
    -- 1) Ignora buffers que no son archivos “normales”
    if vim.bo.buftype ~= "" then return end               -- no prompt/help/terminal/etc
    if vim.api.nvim_buf_get_name(0) == "" then return end -- buffers sin archivo

    -- 2) Decide por filetype
    local ft = vim.bo.filetype
    -- if ft == "c" or ft == "cpp" then
    --     if current ~= "gruvbox" then
    --         current = "gruvbox"
    --         load_and_set("gruvbox", "gruvbox")
    --         set_gruvbox_bg()
    --         normalize_c_highlights()
    --         set_pretty_selection_for_gruvbox()
    --     end
    if ft == "c" or ft == "cpp" or ft == "rust" then
        if current ~= "sunbather" then
            current = "sunbather"

            -- carga el plugin y setea el colorscheme SOLO aquí
            load_and_set("sunbather", "vim-sunbather")
            soften_visual_selection()
            soften_type_colors()
            disable_italics()

            -- si quieres tus overrides de C/C++ los dejas
            -- (ojo: tus colores son gruvbox-ish, pero sirven igual)
            -- normalize_c_highlights()
            -- set_pretty_selection_for_gruvbox()
            -- set_transparent() -- si lo quieres transparente
        end
    else
        if current ~= "rose-pine" then
            current = "rose-pine"
            load_and_set("rose-pine-moon", "rose-pine")
        end
    end
end

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = aug,
    callback = apply,
})
