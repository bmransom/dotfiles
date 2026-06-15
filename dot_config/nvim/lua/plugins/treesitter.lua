return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- the rewrite; required for Neovim 0.11+ (master is frozen for <=0.10)
    lazy = false, -- main does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      -- Transition guard: during a branch switch lazy may load this before checking
      -- out main. The old master module has no install(); skip until main is in place.
      if type(ts.install) ~= "function" then
        return
      end

      ts.install({
        "lua", "luadoc", "vim", "vimdoc", "query", "bash", "json",
        "yaml", "toml", "markdown", "markdown_inline", "html", "css", "scss",
        "javascript", "typescript", "tsx", "python", "rust", "c", "cpp",
        "dockerfile", "git_config", "gitcommit", "diff", "regex",
      })

      -- main dropped the highlight/indent modules; enable them natively per buffer.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      -- Migrated to main for 0.12 compatibility. No text-object keymaps configured yet.
      pcall(function()
        require("nvim-treesitter-textobjects").setup({})
      end)
    end,
  },
}
