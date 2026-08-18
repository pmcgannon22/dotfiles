# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## My customizations (non-default LazyVim)

- `lua/config/options.lua`: local option overrides (terminal title, etc.)
- `lua/config/keymaps.lua`: custom keymap overrides (see below)
- `lua/plugins/*.lua`: custom plugin specs and overrides (`csharp.lua`, `java.lua`, `octo.lua`, `review.lua`)
- `ftplugin/*.lua`: filetype-local settings (`ftplugin/java.lua`)

If you copy this whole `nvim` folder to a new machine, these files are the parts that differ from stock LazyVim behavior.

## Custom keymaps

| Key | Action |
|-----|--------|
| `jj` | Exit insert mode (alias for `<Esc>`) |
| `<leader><leader>` | Smart file search, scoped to the Neovim launch directory (not the current buffer's detected root) |

The `<leader><leader>` override prevents the search scope from drifting when jumping between files in different subtrees — a common issue in WSL where nested `.git` markers cause `LazyVim.root()` to re-scope per buffer.

## Current language/tooling customizations

### WSL2 clipboard

- Uses Windows interoperability for the `+` and `*` registers when Neovim runs under WSL
- Copies through `clip.exe` and pastes through PowerShell's `Get-Clipboard`
- Requires Windows interoperability to be enabled in WSL

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

### Neovim practice tools

#### Precognition (`tris203/precognition.nvim`)

Precognition displays contextual motion and text-object hints directly in the current buffer. It is disabled by
default to avoid adding cursor-movement overhead; use the commands below when you want hints.

- `:Precognition toggle` - toggle hints for the current session
- `:Precognition show` - show hints
- `:Precognition hide` - hide hints
- `:Precognition peek` - show hints until the next cursor movement

#### Hardtime (`m4xshen/hardtime.nvim`)

Hardtime watches for repetitive movement habits and suggests more effective Vim motions. This configuration uses
hint-only restrictions and leaves the mouse and arrow keys available. Its local adapter also restores any existing
Normal-mode mappings after Hardtime is disabled, so toggling it does not remove LazyVim or custom mappings.

- `:Hardtime toggle` - toggle Hardtime for the current Neovim session
- `:Hardtime enable` - enable Hardtime
- `:Hardtime disable` - disable Hardtime
- `:Hardtime report` - show the most frequently encountered hints

Hardtime starts enabled. To change that default, set `enabled = false` in `lua/plugins/hardtime.lua`.

#### Key usage logging

`KeyUsage` is a custom, repository-local Lua module in `lua/key_usage/init.lua`; it is not an external Neovim
plugin. It records all user-typed input in Normal, operator-pending, Visual, and Select modes. It does not record
Insert/Replace text, command-line or search text, or terminal input. Each event contains the typed key sequence,
mode, filetype, buffer type, timing, and matching keymap description when one can be resolved.

Events are buffered and written as daily JSONL files under `stdpath("state")/key-usage`. Run `:KeyUsage path` to
show the exact directory for the current machine.

- `:KeyUsage` or `:KeyUsage status` - show whether logging is enabled
- `:KeyUsage toggle` - toggle logging for the current session
- `:KeyUsage enable` - enable logging
- `:KeyUsage disable` - flush pending events and disable logging
- `:KeyUsage flush` - immediately write pending events
- `:KeyUsage path` - show the log directory

The logger intentionally stores low-level events rather than guessing at complete Vim commands. Later reporting can
combine these events with keymap metadata to derive semantic actions without changing mapping behavior. Normal-mode
character arguments such as the target of `f`, `t`, or `r` are part of the recorded key stream.

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

### Review (`georgeguimaraes/review.nvim`)

Review is configured in `lua/plugins/review.lua` for annotating local Git diffs and exporting the comments as
AI-ready Markdown. It complements Octo: use Octo to publish GitHub PR reviews and Review to send structured local
feedback to an AI agent.

#### Entry points

- `<leader>rv` or `:Review` - review staged and unstaged changes
- `<leader>rV` or `:Review commits` - select commits to review
- `:Review preview` - preview the exported Markdown
- `:Review export` - copy the exported Markdown to the clipboard

#### Review workflow

1. Open a review with `<leader>rv`
2. Navigate files with `<Tab>` and `<S-Tab>`
3. Press `i` on a line, or after selecting a range, to add a comment
4. Use `]n` and `[n` to move between comments
5. Press `C` to export and preview, or `q` to close and automatically copy the Markdown to the clipboard
6. Paste the exported feedback into the AI agent

#### Temporary version pin

Review is pinned to `v1.9.1` and `codediff.nvim` is pinned to `v2.49.0`. `codediff.nvim` v2.50.0 changed its path API
and currently breaks Review's session setup and comment rendering. Revisit these pins after
[`review.nvim` PR #37](https://github.com/georgeguimaraes/review.nvim/pull/37), or an equivalent compatibility fix,
is released.

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
