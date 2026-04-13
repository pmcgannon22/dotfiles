-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-fold import blocks when a file is first opened.
local import_patterns = { "^import ", "^using ", "^from " }
local import_filetypes = { "java", "cs", "typescript", "typescriptreact", "javascript", "javascriptreact", "python", "go", "kotlin" }

local function fold_imports()
  local line_count = vim.api.nvim_buf_line_count(0)
  local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(120, line_count), false)
  for i, line in ipairs(lines) do
    for _, pat in ipairs(import_patterns) do
      if line:match(pat) then
        if vim.fn.foldclosed(i) == -1 and vim.fn.foldlevel(i) > 0 then
          pcall(vim.cmd, i .. "foldclose")
        end
        break
      end
    end
  end
end

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("fold-imports", { clear = true }),
  callback = function()
    if vim.tbl_contains(import_filetypes, vim.bo.filetype) then
      vim.defer_fn(fold_imports, 150)
    end
  end,
})
