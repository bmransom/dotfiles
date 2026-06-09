return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      notifier = { enabled = true },
      input = { enabled = true },
      terminal = { enabled = true },
      picker = { enabled = true, ui_select = true },
    },
    keys = {
      { "<leader>tt", function() Snacks.terminal() end, desc = "Terminal toggle" },
    },
  },
}
