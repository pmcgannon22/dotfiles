return {
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    keys = {
      { "<leader>op", "<cmd>Octo pr list<cr>", desc = "GitHub Pull Requests" },
      { "<leader>or", "<cmd>Octo review<cr>", desc = "Review Pull Request" },
    },
    opts = {
      picker = "telescope",
      enable_builtin = true,
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
  },
}
