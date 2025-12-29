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

-- evita recalcular y evita “parpadeos”
local current = nil
local function apply()
    -- 1) Ignora buffers que no son archivos “normales”
    if vim.bo.buftype ~= "" then return end               -- no prompt/help/terminal/etc
    if vim.api.nvim_buf_get_name(0) == "" then return end -- buffers sin archivo

    -- 2) Decide por filetype
    local ft = vim.bo.filetype
    if ft == "c" or ft == "cpp" then
        if current ~= "gruvbox" then
            current = "gruvbox"
            load_and_set("gruvbox", "gruvbox")
            set_gruvbox_bg()
            normalize_c_highlights()
            set_pretty_selection_for_gruvbox()
        end
    else
        if current ~= "rose-pine" then
            current = "rose-pine"
            load_and_set("rose-pine-moon", "rose-pine")
            set_transparent()
        end
    end
end

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = aug,
    callback = apply,
})
