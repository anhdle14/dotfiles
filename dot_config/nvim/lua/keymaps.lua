-- Define common options
local opts = {
	noremap = true, -- non-recursive
	silent = true, -- do not show message
}

-- Default leader key: <space>
vim.g.mapleader = " "

-- Delete without yanking (sends to the black hole register)
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d')

-----------------
-- Insert mode --
-----------------
-- Makes <C-c> behave like <Esc> in insert mode.
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Tmux intialize
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-----------------
-- Normal mode --
-----------------
-- Reload config
vim.keymap.set("n", "<leader><leader>", function()
	vim.cmd("so")
end)

-- Hint: see `:h vim.map.set()`
-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
-- delta: 2 lines
vim.keymap.set("n", "<C-Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<C-Down>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- For Netrw
vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

-- For nvim-surround
--     Old text                    Command         New text
-- --------------------------------------------------------------------------------
--     surr*ound_words             ysiw)           (surround_words)
--     *make strings               ys$"            "make strings"
--     [delete ar*ound me!]        ds]             delete around me!
--     remove <b>HTML t*ags</b>    dst             remove HTML tags
--     'change quot*es'            cs'"            "change quotes"
--     <b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>

-- Join lines but keeps the cursor in place
vim.keymap.set("n", "J", "mzJ`z")

-- Scrolls half a page down or up and center the cursor
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- After searching with `/`, center the next and previous match and opens folds.
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Auto indent the last pasted text
vim.keymap.set("n", "=ap", "ma=ap'a")

-- Restart the LSP server
vim.keymap.set("n", "<leader>lsp", "<cmd>LspRestart<cr>")

-- Disables the rarely-used `Q` command (Ex-mode)
vim.keymap.set("n", "Q", "<nop>")

-- Tmux integration
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Format the current file using conform plugin
vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ bufnr = 0 })
end)

-- Navigate the quickfix list
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")

-- Navigate the location list
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Find & Replace on the current word, case-insensitive
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Makes the current file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Buffers navigation
vim.keymap.set("n", "<C-Tab>", ":bnext<CR>")
vim.keymap.set("n", "<C-S-Tab>", ":bprev<CR>")

-----------------
-- Visual mode --
-----------------

-- Hint: start visual mode with the same area as the previous area and the same mode
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-- For nvim-treesitter
-- 1. Press `gss` to intialize selection. (ss = start selection)
-- 2. Now we are in the visual mode.
-- 3. Press `gsi` to increment selection by AST node. (si = selection incremental)
-- 4. Press `gsc` to increment selection by scope. (sc = scope)
-- 5. Press `gsd` to decrement selection. (sd = selection decrement)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Paste in visual model without overwriting the clipboard
vim.keymap.set("x", "<leader>v", [["_dP]])

-- Yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
