-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- User customizations (portable between machines)
vim.o.title = true
vim.o.titlestring = "📝 nvim: %t%(%M%)"

if vim.fn.has("win32") == 1 then
  LazyVim.terminal.setup("pwsh")
else
  LazyVim.terminal.setup(vim.fn.executable("zsh") == 1 and "zsh" or "bash")
end

vim.lsp.set_log_level("ERROR")
