local map = vim.keymap.set

-- save / quit
map("n", "<leader>s", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit all" })

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- better up/down on wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- keep selection when indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

-- open the current file in the system default app (Preview for images/PDFs, etc.)
map("n", "<leader>o", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No file to open", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ "open", file }, { detach = true })
end, { desc = "Open in system app" })

-- NOTE: window/pane nav (<C-h/j/k/l>) is provided by vim-tmux-navigator (later phase),
-- and commenting uses the built-in gc/gcc (Neovim 0.10+).
