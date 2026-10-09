return {
  {
    "georgeguimaraes/review.nvim",
    version = "v1.9.1",
    cmd = "Review",
    keys = {
      { "<leader>rv", "<cmd>Review<cr>", desc = "Review Local Changes" },
      { "<leader>rV", "<cmd>Review commits<cr>", desc = "Review Commits" },
    },
    dependencies = {
      {
        "esmuellert/codediff.nvim",
        version = "v2.49.0",
      },
      "MunifTanjim/nui.nvim",
    },
    opts = {},
  },
}
