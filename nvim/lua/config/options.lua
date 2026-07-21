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

if vim.fn.has("wsl") == 1 then
  local paste_command =
    "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoLogo -NoProfile -Command '$text = Get-Clipboard -Raw; if ($null -ne $text) { [Console]::Out.Write($text.Replace(\"`r\", \"\")) }'"

  vim.g.clipboard = {
    name = "WSL clipboard",
    copy = {
      ["+"] = "/mnt/c/Windows/System32/clip.exe",
      ["*"] = "/mnt/c/Windows/System32/clip.exe",
    },
    paste = {
      ["+"] = paste_command,
      ["*"] = paste_command,
    },
    cache_enabled = 0,
  }
end

if vim.fn.has("win32") == 1 then
  LazyVim.terminal.setup("pwsh")
else
  LazyVim.terminal.setup(vim.fn.executable("zsh") == 1 and "zsh" or "bash")
end

vim.lsp.set_log_level("ERROR")

-- Neovide-only settings. These have no effect in terminal Neovim.
if vim.g.neovide then
  vim.g.neovide_scale_factor = 1.0
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_left = 0
  vim.g.neovide_padding_right = 0

  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size = 0.2
  vim.g.neovide_scroll_animation_length = 0.2
  vim.g.neovide_scroll_animation_far_lines = 1
  vim.g.neovide_position_animation_length = 0.1

  vim.g.neovide_hide_mouse_when_typing = true
  vim.g.neovide_theme = "auto"

  -- System clipboard paste in insert/command modes (Windows/Linux convention).
  vim.keymap.set({ "n", "v" }, "<C-S-c>", '"+y', { desc = "Copy to system clipboard" })
  vim.keymap.set({ "n", "v" }, "<C-S-v>", '"+P', { desc = "Paste from system clipboard" })
  vim.keymap.set("i", "<C-S-v>", "<C-r><C-o>+", { desc = "Paste from system clipboard" })
  vim.keymap.set("c", "<C-S-v>", "<C-r>+", { desc = "Paste from system clipboard" })
  vim.keymap.set("t", "<C-S-v>", [[<C-\><C-n>"+Pi]], { desc = "Paste from system clipboard" })

  -- Dynamic font scaling (handy for presentations / quick zoom).
  local function change_scale(delta)
    vim.g.neovide_scale_factor = math.max(0.5, (vim.g.neovide_scale_factor or 1.0) + delta)
  end
  vim.keymap.set("n", "<C-=>", function() change_scale(0.1) end, { desc = "Neovide: zoom in" })
  vim.keymap.set("n", "<C-->", function() change_scale(-0.1) end, { desc = "Neovide: zoom out" })
  vim.keymap.set("n", "<C-0>", function() vim.g.neovide_scale_factor = 1.0 end, { desc = "Neovide: reset zoom" })
end
