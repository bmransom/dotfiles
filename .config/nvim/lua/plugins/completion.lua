return {
  "saghen/blink.cmp",
  version = "1.*", -- release tag ships a prebuilt fuzzy binary
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
    { "L3MON4D3/LuaSnip", version = "2.*" },
  },
  opts = {
    keymap = { preset = "default" }, -- <C-space> menu, <C-n>/<C-p>, <C-y> accept
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      menu = { auto_show = true },
    },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    snippets = { preset = "luasnip" },
    signature = { enabled = true },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
