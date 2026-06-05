-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- User customizations (portable between machines)
-- Title the process tab with the current git project (or root dir) name
-- instead of the file name. Cached per-directory so it isn't recomputed on
-- every redraw.
local title_cache = {}
local function title_project()
  local name = vim.api.nvim_buf_get_name(0)
  local dir = name ~= "" and vim.fs.dirname(name) or (vim.uv or vim.loop).cwd()
  local cached = title_cache[dir]
  if cached then
    return cached
  end
  local root = vim.fs.root(dir, ".git") or (vim.uv or vim.loop).cwd()
  local project = vim.fn.fnamemodify(root, ":t")
  title_cache[dir] = project
  return project
end
_G.title_project = title_project

vim.o.title = true
vim.o.titlestring = "📝 %{v:lua.title_project()}%( %M%)"

if vim.fn.has("win32") == 1 then
  LazyVim.terminal.setup("pwsh")
else
  LazyVim.terminal.setup(vim.fn.executable("zsh") == 1 and "zsh" or "bash")
end

vim.lsp.set_log_level("ERROR")
