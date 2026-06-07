-- Leader MUST be set before lazy/plugins load.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
local indent = 4

vim.cmd("filetype plugin indent on")

opt.clipboard = "unnamedplus"
opt.fileencoding = "utf-8"
opt.termguicolors = true

-- indentation
opt.expandtab = true
opt.shiftwidth = indent
opt.softtabstop = indent
opt.tabstop = indent
opt.smartindent = true
opt.shiftround = true

-- search
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.wildignore:append({ "*/node_modules/*", "*/.git/*", "*/vendor/*" })

-- ui
opt.number = true
opt.relativenumber = false
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 10
opt.sidescrolloff = 3
opt.splitbelow = true
opt.splitright = true
opt.wrap = false
opt.laststatus = 3 -- global statusline (lualine globalstatus)
opt.showmode = false
opt.cmdheight = 1
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- files / undo
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 1000

-- behaviour
opt.mouse = "a"
opt.updatetime = 200
opt.timeoutlen = 300
opt.completeopt = { "menu", "menuone", "noselect" }

-- AI/Claude glue: auto-reload files changed on disk (pairs with tmux focus-events)
opt.autoread = true

-- folds (treesitter-aware later; keep open by default)
opt.foldlevel = 99
opt.foldlevelstart = 99
