-- core settings first (sets leader before lazy)
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  defaults = { lazy = true }, -- lazy by default; startup-critical specs set lazy = false
  install = { colorscheme = { "rose-pine", "habamax" } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  performance = { rtp = { disabled_plugins = { "netrwPlugin", "tutor" } } },
})
