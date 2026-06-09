return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft", "TmuxNavigateDown",
    "TmuxNavigateUp", "TmuxNavigateRight",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Nav left (split/pane)" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Nav down (split/pane)" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Nav up (split/pane)" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Nav right (split/pane)" },
  },
}
