return {
  -- Mason package manager
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog" },
    opts = { ui = { border = "rounded" } },
  },

  -- Lua dev: API/plugin awareness for editing this config
  { "folke/lazydev.nvim", ft = "lua", opts = {} },

  -- LSP via native vim.lsp.config + mason-lspconfig v2
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim" },
      { "mason-org/mason-lspconfig.nvim" },
      { "WhoIsSethDaniel/mason-tool-installer.nvim" },
      "saghen/blink.cmp",
    },
    config = function()
      require("mason").setup({ ui = { border = "rounded" } })

      -- lspconfig-name -> per-server settings ({} = defaults)
      local servers = {
        ts_ls = {},
        eslint = {},
        html = {},
        cssls = {},
        emmet_ls = {},
        jsonls = {},
        yamlls = {},
        dockerls = {},
        bashls = {},
        clangd = {},
        marksman = {},
        basedpyright = {},
        ruff = {
          -- basedpyright owns hover/docs; ruff handles lint + format only
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },
        lua_ls = {
          settings = { Lua = { completion = { callSnippet = "Replace" } } },
        },
      }

      -- completion capabilities from blink.cmp
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end
      vim.lsp.config("*", { capabilities = capabilities })

      -- per-server overrides
      for server, cfg in pairs(servers) do
        if next(cfg) ~= nil then
          vim.lsp.config(server, cfg)
        end
      end

      -- install + auto-enable (vim.lsp.enable) all listed servers
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        -- exclude formatters that ship an lspconfig entry (stylua) so they
        -- don't get auto-enabled as redundant formatting-only LSP servers;
        -- conform.nvim runs them as CLI tools instead.
        automatic_enable = { exclude = { "stylua" } },
      })

      -- non-LSP tools (formatters, linters, DAP adapters)
      require("mason-tool-installer").setup({
        ensure_installed = {
          "stylua", "prettierd", "prettier", "shfmt", "clang-format",
          "markdownlint", "shellcheck",
          "debugpy", "js-debug-adapter", "codelldb",
        },
      })

      -- a couple of extra LSP maps on top of the 0.11 built-ins (grn/gra/grr/gri/K)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach_maps", { clear = true }),
        callback = function(ev)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })
    end,
  },

  -- Rust: rustaceanvim configures rust_analyzer + codelldb itself (NOT via mason-lspconfig)
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = { "rust" },
  },
}
