vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<leader>zig", "<cmd>LspRestart<cr>")

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", "\"_d")

-- This is going to get me cancelled
vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
-- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
)

vim.keymap.set(
    "n",
    "<leader>ea",
    "oassert.NoError(err, \"\")<Esc>F\";a"
)

vim.keymap.set(
    "n",
    "<leader>ef",
    "oif err != nil {<CR>}<Esc>Olog.Fatalf(\"error: %s\\n\", err.Error())<Esc>jj"
)

vim.keymap.set(
    "n",
    "<leader>el",
    "oif err != nil {<CR>}<Esc>O.logger.Error(\"error\", \"error\", err)<Esc>F.;i"
)

vim.keymap.set("n", "<leader>vpp", "<cmd>e ~/.dotfiles/nvim/.config/nvim/lua/theprimeagen/packer.lua<CR>");
vim.keymap.set("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>");


-- My keymaps for nvim from my main config
-- General keymaps
vim.keymap.set("i", "jk", "<ESC>")                                                                -- escape
vim.keymap.set('n', "<leader>wq", ":wq<CR>")                                                      -- save and quit
vim.keymap.set('n', "<leader>qq", ":q!<CR>")                                                      -- quit without saving
vim.keymap.set('n', "<leader>ww", ":w<CR>")                                                       -- save file
vim.keymap.set('n', "<leader>gx", ":!open <c-r><c-a><CR>")                                        -- open URL under cursor
vim.keymap.set({ 'n', 'v' }, '<leader>/', ':CommentToggle<CR>', { noremap = true, silent = true }) -- Comment line


vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
--
-- Split window management
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })          -- split window vertically
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })        -- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })           -- make split windows equal width
vim.keymap.set("n", "<leader>sx", ":close<CR>", { desc = "Close current split" })          -- close split window
vim.keymap.set("n", "<leader>sj", "<C-w>-", { desc = "Make split window height shorter" }) -- make split window height shorter
vim.keymap.set("n", "<leader>sk", "<C-w>+", { desc = "Make split window height taller" })  -- make split window height taller
vim.keymap.set("n", "<leader>sl", "<C-w>>5", { desc = "Make split window width bigger" })  -- make split window width bigger
vim.keymap.set("n", "<leader>ss", "<C-w><5", { desc = "Make split window width smaller" }) -- make split window width smaller

-- Tab management
vim.keymap.set("n", "<leader>to", ":tabnew<CR>", { desc = "Open a new tab" }) -- open a new tab
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "Close a tab" })  -- close a tab
vim.keymap.set("n", "<leader>tn", ":tabn<CR>", { desc = "Next tab" })         -- next tab
vim.keymap.set("n", "<leader>tp", ":tabp<CR>", { desc = "Previous tab" })

-- Telescope config.
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files)
vim.keymap.set('n', '<leader>fg', builtin.live_grep)
vim.keymap.set('n', '<leader>fb', builtin.buffers)
vim.keymap.set('n', '<leader>fh', builtin.help_tags)


-- NvChad some mappings
vim.keymap.set('i', '<C-k>', '<Up>')    -- Move Up
vim.keymap.set('i', '<C-j>', '<Down>')  -- Move Up
vim.keymap.set('i', '<C-h>', '<Left>')  -- Move Up
vim.keymap.set('i', '<C-l>', '<Right>') -- Move Up
--vim.keymap.set('i', '{', '{}<Left>');
--vim.keymap.set('i', '(', '()<Left>');
--vim.keymap.set('i', '[', '[]<Left>');
--vim.keymap.set('i', '"', '""<Left>');
--vim.keymap.set('i', "'", "''<Left>");

-- Harpooon

vim.keymap.set('n', '<Leader>a', ':lua require("harpoon.mark").add_file()<CR>',
    { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>h', ':lua require("harpoon.ui").toggle_quick_menu()<CR>',
    { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>1', ':lua require("harpoon.ui").nav_file(1)<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>2', ':lua require("harpoon.ui").nav_file(2)<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>3', ':lua require("harpoon.ui").nav_file(3)<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>4', ':lua require("harpoon.ui").nav_file(4)<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>hn', ':lua require("harpoon.ui").nav_next()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>hp', ':lua require("harpoon.ui").nav_prev()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>ht', ':lua require("harpoon.term").gotoTerminal(1)<CR>', { noremap = true, silent = true })
-- vim.keymap.set('n', '<Leader>ht', ':lua require("harpoon.term").gotoTerminal(1); vim.cmd("startinsert | term tmux")<CR>', { noremap = true, silent = true })

-- LSP keymaps.
vim.keymap.set('n', '<leader>gg', '<cmd>lua vim.lsp.buf.hover()<CR>', { desc = "Muestra información sobre el símbolo bajo el cursor" })
vim.keymap.set('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { desc = "Va a la definición del símbolo bajo el cursor" })
vim.keymap.set('n', '<leader>gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', { desc = "Va a la declaración del símbolo bajo el cursor" })
vim.keymap.set('n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', { desc = "Muestra las implementaciones del símbolo bajo el cursor" })
vim.keymap.set('n', '<leader>gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', { desc = "Muestra la definición del tipo del símbolo bajo el cursor" })
vim.keymap.set('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', { desc = "Muestra las referencias del símbolo bajo el cursor" })
vim.keymap.set('n', '<leader>gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { desc = "Muestra la ayuda de firma del símbolo bajo el cursor" })
vim.keymap.set('n', '<leader>rr', '<cmd>lua vim.lsp.buf.rename()<CR>', { desc = "Renombra el símbolo bajo el cursor" })
vim.keymap.set('n', '<leader>gf', '<cmd>lua vim.lsp.buf.format({async = true})<CR>', { desc = "Formatea el archivo actual (modo normal)" })
vim.keymap.set('v', '<leader>gf', '<cmd>lua vim.lsp.buf.format({async = true})<CR>', { desc = "Formatea el texto seleccionado (modo visual)" })
vim.keymap.set('n', '<leader>ga', '<cmd>lua vim.lsp.buf.code_action()<CR>', { desc = "Muestra las acciones de código disponibles" })
vim.keymap.set('n', '<leader>gl', '<cmd>lua vim.diagnostic.open_float()<CR>', { desc = "Muestra un flotante con los diagnósticos del cursor" })
vim.keymap.set('n', '<leader>gp', '<cmd>lua vim.diagnostic.goto_prev()<CR>', { desc = "Navega al diagnóstico anterior" })
vim.keymap.set('n', '<leader>gn', '<cmd>lua vim.diagnostic.goto_next()<CR>', { desc = "Navega al diagnóstico siguiente" })
vim.keymap.set('n', '<leader>tr', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', { desc = "Muestra los símbolos del documento actual" })
vim.keymap.set('i', '<C-Space>', '<cmd>lua vim.lsp.buf.completion()<CR>', { desc = "Muestra las sugerencias de autocompletado" })

-- GENERATE GETTERS AND SETTERS IN JAVA.
vim.api.nvim_set_keymap('n', '<leader>ggs', ':GenGetSet<CR>', { noremap = true, silent = true })

