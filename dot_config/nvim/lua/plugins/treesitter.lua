return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "luadoc", "vim", "vimdoc", "query", "bash", "json", "jsonc",
          "yaml", "toml", "markdown", "markdown_inline", "html", "css", "scss",
          "javascript", "typescript", "tsx", "python", "rust", "c", "cpp",
          "dockerfile", "git_config", "gitcommit", "diff", "regex",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "master",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
}
