-- lua/config/keymaps.lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set
local opts = { silent = true }

-- =========================
-- Basics / Quality of life
-- =========================
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Explorer", silent = true })

-- Move selected lines
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Keep cursor centered
map("n", "J", "mzJ`z", opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- LSP restart
map("n", "<leader>zig", "<cmd>LspRestart<cr>", { desc = "LSP restart", silent = true })

-- Clipboard / delete
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking", silent = true })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard", silent = true })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard", silent = true })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to void", silent = true })

-- Insert: Ctrl+c as Esc (si te mola)
map("i", "<C-c>", "<Esc>", opts)

-- Disable Ex mode
map("n", "Q", "<nop>", opts)

-- chmod +x current file
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { desc = "chmod +x current file", silent = true })

-- Replace word under cursor
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word", silent = true })

-- =========================
-- Quickfix / Loclist
-- =========================
map("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Quickfix next", silent = true })
map("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Quickfix prev", silent = true })
map("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Loclist next", silent = true })
map("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Loclist prev", silent = true })

-- =========================
-- Formatting (mejor con Conform, pero fallback a LSP)
-- =========================
map("n", "<leader>f", function()
    -- Si Conform existe, úsalo. Si no, usa LSP format.
    local ok, conform = pcall(require, "conform")
    if ok then
        conform.format({ lsp_fallback = true, timeout_ms = 1000 })
    else
        vim.lsp.buf.format({ async = true })
    end
end, { desc = "Format file", silent = true })

-- =========================
-- Comment toggle (nvim-comment)
-- =========================
map({ "n", "v" }, "<leader>/", ":CommentToggle<CR>", { noremap = true, silent = true, desc = "Toggle comment" })

-- =========================
-- Save / Quit
-- =========================
map("n", "<leader>ww", "<cmd>w<CR>", {
    desc = "Save file",
    silent = true,
})

map("n", "<leader>wq", "<cmd>wq<CR>", {
    desc = "Save & quit",
    silent = true,
})

map("n", "<leader>qq", "<cmd>q!<CR>", {
    desc = "Quit without saving",
    silent = true,
})

map("n", "<leader>wa", "<cmd>wa<CR>", {
    desc = "Save all",
    silent = true,
})

map("n", "<leader>qa", "<cmd>qa<CR>", {
    desc = "Quit all",
    silent = true,
})

-- =========================
-- Splits
-- =========================
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertical", silent = true })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontal", silent = true })
map("n", "<leader>se", "<C-w>=", { desc = "Equalize splits", silent = true })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close split", silent = true })
map("n", "<leader>sj", "<C-w>-", { desc = "Split shorter", silent = true })
map("n", "<leader>sk", "<C-w>+", { desc = "Split taller", silent = true })
map("n", "<leader>sl", "<C-w>>5", { desc = "Split wider", silent = true })
map("n", "<leader>ss", "<C-w><5", { desc = "Split narrower", silent = true })

-- =========================
-- Split navigation (PRO)
-- =========================
-- map("n", "<C-h>", "<C-w>h", { desc = "Move to left split", silent = true })
-- map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom split", silent = true })
-- map("n", "<C-k>", "<C-w>k", { desc = "Move to top split", silent = true })
-- map("n", "<C-l>", "<C-w>l", { desc = "Move to right split", silent = true })

-- =========================
-- Tabs
-- =========================
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "New tab", silent = true })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close tab", silent = true })
map("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Next tab", silent = true })
map("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Prev tab", silent = true })

-- =========================
-- Open URL under cursor (Linux)
-- =========================
map("n", "<leader>gx", function()
    local url = vim.fn.expand("<cWORD>")
    if url and url ~= "" then
        vim.fn.jobstart({ "xdg-open", url }, { detach = true })
    end
end, { desc = "Open URL under cursor", silent = true })

-- =========================
-- Telescope (NO require para que no explote el init)
-- Lazy lo carga solo si en plugins pusiste cmd = "Telescope"
-- =========================
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files", silent = true })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep", silent = true })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers", silent = true })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags", silent = true })

-- =========================
-- Harpoon (safe require para que no explote si no está)
-- =========================
local function harpoon(fn)
    return function()
        local ok, h = pcall(require, "harpoon")
        if not ok then
            vim.notify("Harpoon no está cargado aún (:Lazy sync)", vim.log.levels.WARN)
            return
        end
        fn(h)
    end
end

map("n", "<leader>ha", harpoon(function() require("harpoon.mark").add_file() end),
    { desc = "Harpoon add", silent = true })
map("n", "<leader>h", harpoon(function() require("harpoon.ui").toggle_quick_menu() end),
    { desc = "Harpoon menu", silent = true })
map("n", "<leader>1", harpoon(function() require("harpoon.ui").nav_file(1) end), { desc = "Harpoon 1", silent = true })
map("n", "<leader>2", harpoon(function() require("harpoon.ui").nav_file(2) end), { desc = "Harpoon 2", silent = true })
map("n", "<leader>3", harpoon(function() require("harpoon.ui").nav_file(3) end), { desc = "Harpoon 3", silent = true })
map("n", "<leader>4", harpoon(function() require("harpoon.ui").nav_file(4) end), { desc = "Harpoon 4", silent = true })
map("n", "<leader>hn", harpoon(function() require("harpoon.ui").nav_next() end), { desc = "Harpoon next", silent = true })
map("n", "<leader>hp", harpoon(function() require("harpoon.ui").nav_prev() end), { desc = "Harpoon prev", silent = true })
map("n", "<leader>ht", harpoon(function() require("harpoon.term").gotoTerminal(1) end),
    { desc = "Harpoon terminal", silent = true })

-- -- =========================
-- -- Primeagen Go error snippets (los dejo como los tenías)
-- -- =========================
-- map("n", "<leader>ee", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>", opts)
-- map("n", "<leader>ea", "oassert.NoError(err, \"\")<Esc>F\";a", opts)
-- map("n", "<leader>ef", "oif err != nil {<CR>}<Esc>Olog.Fatalf(\"error: %s\\n\", err.Error())<Esc>jj", opts)
-- map("n", "<leader>el", "oif err != nil {<CR>}<Esc>O.logger.Error(\"error\", \"error\", err)<Esc>F.;i", opts)

-- =========================
-- Java: Generate getters/setters
-- =========================
vim.api.nvim_set_keymap("n", "<leader>ggs", ":GenGetSet<CR>", { noremap = true, silent = true })

-- =========================
-- (Opcional) "jk" para salir de insert
-- =========================
map("i", "jk", "<Esc>", { desc = "Escape", silent = true })

-- =========================
-- NvChad-like insert arrows (OJO: pisa Ctrl-j/k que usas en normal para quickfix, pero en insert no pasa nada)
-- =========================
map("i", "<C-k>", "<Up>", opts)
map("i", "<C-j>", "<Down>", opts)
map("i", "<C-h>", "<Left>", opts)
map("i", "<C-l>", "<Right>", opts)

-- =========================
-- GitSigns keymaps (robusto)
-- =========================
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    callback = function()
        local ok, gs = pcall(require, "gitsigns")
        if not ok then return end

        -- Para no re-mapear 200 veces
        if vim.g.__gitsigns_keymaps_set then return end
        vim.g.__gitsigns_keymaps_set = true

        vim.keymap.set("n", "]c", gs.next_hunk, { desc = "Next git hunk", silent = true })
        vim.keymap.set("n", "[c", gs.prev_hunk, { desc = "Prev git hunk", silent = true })

        vim.keymap.set("n", "<leader>gs", gs.stage_hunk, { desc = "Git stage hunk", silent = true })
        vim.keymap.set("n", "<leader>gr", gs.reset_hunk, { desc = "Git reset hunk", silent = true })
        vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { desc = "Git preview hunk", silent = true })
        vim.keymap.set("n", "<leader>gb", gs.blame_line, { desc = "Git blame line", silent = true })

        vim.keymap.set("n", "<leader>gS", gs.stage_buffer, { desc = "Git stage buffer", silent = true })
        vim.keymap.set("n", "<leader>gR", gs.reset_buffer, { desc = "Git reset buffer", silent = true })
    end,
})

-- =========================
-- Oil.nvim keymaps
-- =========================
map("n", "<leader>e", "<cmd>Oil<CR>", {
    desc = "Open Oil file explorer",
    silent = true,
})
