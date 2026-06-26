-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-fold import blocks when a file is first opened.
-- Retries until treesitter has computed fold levels.
local import_patterns = { "^import ", "^using ", "^from " }

local function fold_imports(attempts)
  attempts = attempts or 0
  local scan = math.min(120, vim.api.nvim_buf_line_count(0))
  local lines = vim.api.nvim_buf_get_lines(0, 0, scan, false)

  local has_folds = false
  for i = 1, scan do
    if vim.fn.foldlevel(i) > 0 then
      has_folds = true
      break
    end
  end

  if not has_folds then
    if attempts < 15 then
      vim.defer_fn(function()
        fold_imports(attempts + 1)
      end, 200)
    end
    return
  end

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

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("fold-imports", { clear = true }),
  pattern = { "java", "cs", "typescript", "typescriptreact", "javascript", "javascriptreact", "python", "go", "kotlin" },
  callback = function()
    vim.defer_fn(fold_imports, 200)
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("trim-whitespace", { clear = true }),
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" or vim.bo[args.buf].binary or not vim.bo[args.buf].modifiable then
      return
    end

    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_call(args.buf, function()
      vim.cmd([[silent! keepjumps keeppatterns %s/[ \t]\+$//e]])
    end)
    vim.fn.winrestview(view)
  end,
})
