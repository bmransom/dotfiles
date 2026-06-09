local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- highlight yanked text (modern vim.hl API)
autocmd("TextYankPost", {
  group = augroup("yank_highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- reload files changed on disk (AI/Claude glue)
autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose", "TermLeave" }, {
  group = augroup("auto_read", { clear = true }),
  command = "checktime",
})

-- 2-space indent for web/markup/config filetypes
autocmd("FileType", {
  group = augroup("two_space_ft", { clear = true }),
  pattern = { "html", "css", "scss", "javascript", "javascriptreact",
    "typescript", "typescriptreact", "json", "jsonc", "yaml", "lua", "markdown" },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})

-- colorcolumn for languages with line-length conventions
autocmd("FileType", {
  group = augroup("colorcolumn_ft", { clear = true }),
  pattern = { "python", "c", "cpp", "rust" },
  command = "setlocal colorcolumn=88",
})

-- prose: wrap + spell
autocmd("FileType", {
  group = augroup("prose_ft", { clear = true }),
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})
