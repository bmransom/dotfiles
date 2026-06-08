return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  keys = {
    { "<leader>n", "<cmd>Neotree toggle<cr>", desc = "Explorer toggle" },
    { "<leader>nf", "<cmd>Neotree reveal<cr>", desc = "Reveal current file" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    close_if_last_window = true,
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = "open_default",
      filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
    },
    window = {
      width = 32,
      mappings = {
        -- open the file/folder under the cursor in the system default app (Preview, etc.)
        ["O"] = function(state)
          local node = state.tree:get_node()
          if node then
            vim.fn.jobstart({ "open", node:get_id() }, { detach = true })
          end
        end,
      },
    },
  },
}
