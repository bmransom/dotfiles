return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "Markdown render toggle" },
      { "<leader>mp", "<cmd>RenderMarkdown preview<cr>", desc = "Markdown preview split" },
    },
  },
}
