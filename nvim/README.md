# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## My customizations (non-default LazyVim)

- `lua/config/options.lua`: local option overrides (terminal title, etc.)
- `lua/plugins/*.lua`: custom plugin specs and overrides (`csharp.lua`, `java.lua`, `octo.lua`)
- `ftplugin/*.lua`: filetype-local settings (`ftplugin/java.lua`)

If you copy this whole `nvim` folder to a new machine, these files are the parts that differ from stock LazyVim behavior.

## Current language/tooling customizations

### Java

- Enables the LazyVim Java extra from `lazyvim.json`
- Installs `jdtls` and `google-java-format` via Mason
- Formats Java with `google-java-format --aosp` through Conform
- Uses a stable per-project JDTLS workspace under `stdpath("state")/jdtls/<project>`
- Forces 4-space indentation in `ftplugin/java.lua`

### C#

- Uses `roslyn.nvim` for C# buffers
- Adds the Crashdummyy Mason registry so the `roslyn` package can be installed
- Explicitly disables `omnisharp` in `nvim-lspconfig`

## Newest plugin additions

### Octo (`pwntester/octo.nvim`)

Octo is configured in `lua/plugins/octo.lua` and lazy-loads on the `:Octo` command or the custom mappings below.

#### Requirements

- Authenticate GitHub CLI first: `gh auth login`
- If you use GitHub Projects, also run: `gh auth refresh -s read:project`

#### Entry points

- `<leader>op` - open the PR list
- `<leader>or` - start or resume reviewing the current PR
- `:Octo` - open Octo commands directly

#### Review workflow

1. Open a PR with `<leader>op` or `:Octo pr list`
2. Press `<CR>` to open it
3. Run `:Octo review`
4. Use `]q` and `[q` to move between changed files
5. Use review-only mappings:
   - `\ca` - add a review comment
   - `\sa` - add a review suggestion
   - `\vs` - submit the review
   - `\vd` - discard the pending review
6. In the submit-review window:
   - `<C-m>` - submit as comment
   - `<C-a>` - approve
   - `<C-r>` - request changes

`<localleader>` is `\` in this setup, so Octo's default review mappings use backslash-prefixed chords.

### Lazygit

This setup uses LazyVim's built-in lazygit integration. There is no repo-local plugin spec for it; it becomes available automatically when the `lazygit` executable is installed and on `PATH`.

#### Entry points

- `<leader>gg` - open lazygit rooted at the current Git repository
- `<leader>gG` - open lazygit for the current working directory

#### Common lazygit actions

- `?` - open lazygit help
- `space` - stage or unstage the selected file/hunk
- `c` - create a commit
- `P` - push
- `p` - pull
- `q` - close lazygit
