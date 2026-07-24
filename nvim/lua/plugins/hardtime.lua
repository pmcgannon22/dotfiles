return {
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      disable_mouse = false,
      restriction_mode = "hint",
      resetting_keys = {
        ["1"] = "n",
        ["2"] = "n",
        ["3"] = "n",
        ["4"] = "n",
        ["5"] = "n",
        ["6"] = "n",
        ["7"] = "n",
        ["8"] = "n",
        ["9"] = "n",
      },
      restricted_keys = {
        ["h"] = "n",
        ["j"] = "n",
        ["k"] = "n",
        ["l"] = "n",
        ["+"] = "n",
        ["gj"] = "n",
        ["gk"] = "n",
        ["<C-M>"] = "n",
        ["<C-N>"] = "n",
        ["<C-P>"] = "n",
      },
      disabled_keys = {
        ["<Up>"] = false,
        ["<Down>"] = false,
        ["<Left>"] = false,
        ["<Right>"] = false,
      },
    },
    config = function(_, opts)
      require("config.hardtime").setup(opts)
    end,
  },
}
