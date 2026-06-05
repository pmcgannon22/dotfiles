return {
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {
      -- Hand file watching off to the Roslyn server instead of Neovim's
      -- libuv watcher, which recursively walks the whole solution tree and
      -- floods the event loop in large repos.
      filewatching = "roslyn",
    },
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.registries = opts.registries or { "github:mason-org/mason-registry" }
      if not vim.tbl_contains(opts.registries, "github:Crashdummyy/mason-registry") then
        table.insert(opts.registries, "github:Crashdummyy/mason-registry")
      end

      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "roslyn") then
        table.insert(opts.ensure_installed, "roslyn")
      end
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "c_sharp") then
        table.insert(opts.ensure_installed, "c_sharp")
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { enabled = false },
      },
    },
  },
}
