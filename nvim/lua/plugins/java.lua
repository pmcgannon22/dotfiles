return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, tool in ipairs({ "jdtls", "google-java-format" }) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters["google-java-format"] = vim.tbl_deep_extend(
        "force",
        opts.formatters["google-java-format"] or {},
        { prepend_args = { "--aosp" } }
      )

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.java = { "google-java-format" }
    end,
  },

  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      opts.dap_main = false

      -- Stop Neovim's libuv file watcher from recursively watching the whole
      -- project tree (a major freeze source in large repos); let jdtls watch.
      opts.jdtls = vim.tbl_deep_extend("force", opts.jdtls or {}, {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = { dynamicRegistration = false },
          },
        },
      })

      opts.project_name = function(root_dir)
        if not root_dir then
          return nil
        end
        local normalized = vim.fs.normalize(root_dir)
        local base = vim.fs.basename(normalized)
        local hash = vim.fn.sha256(normalized):sub(1, 8)
        return ("%s-%s"):format(base, hash)
      end

      opts.jdtls_config_dir = function(project_name)
        return vim.fn.stdpath("state") .. "/jdtls/" .. project_name .. "/config"
      end

      opts.jdtls_workspace_dir = function(project_name)
        return vim.fn.stdpath("state") .. "/jdtls/" .. project_name .. "/workspace"
      end
    end,
  },
}
