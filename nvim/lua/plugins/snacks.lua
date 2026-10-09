return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      local sources = opts.picker.sources
      sources.files = vim.tbl_deep_extend("force", sources.files or {}, { hidden = true })
      sources.grep = vim.tbl_deep_extend("force", sources.grep or {}, { hidden = true })

      if vim.env.NVIM_USE_TGREP ~= "0" then
        for _, source in ipairs({ "grep", "grep_word", "grep_buffers" }) do
          sources[source] = sources[source] or {}
          sources[source].finder = require("search.tgrep").grep
        end
      end
    end,
  },
}
