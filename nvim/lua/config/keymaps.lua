-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })

-- Pin <leader><leader> to the directory where Neovim was launched.
-- LazyVim's default uses LazyVim.root(), which re-scopes to the current
-- buffer's detected project root on every jump, causing the search scope
-- to drift unexpectedly when navigating across directory trees (common in WSL).
vim.keymap.set("n", "<leader><leader>", function()
  Snacks.picker.smart({ cwd = vim.fn.getcwd() })
end, { desc = "Smart Find Files" })
