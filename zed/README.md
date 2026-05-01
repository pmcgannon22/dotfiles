# Zed Editor Configuration

Personal Zed configuration mirroring our [Neovim/LazyVim](../nvim/) setup. Vim-first, keyboard-driven, minimal friction.

## Installation

### Prerequisites

- [Zed](https://zed.dev/) installed
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) installed
- [PowerShell 7+](https://github.com/PowerShell/PowerShell) (`pwsh`) for the integrated terminal

### Symlink (Windows)

From an **elevated PowerShell** prompt:

```powershell
$dotfiles = "C:\enlistments\dotfiles"

New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Zed\settings.json" -Target "$dotfiles\zed\settings.json" -Force
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Zed\keymap.json" -Target "$dotfiles\zed\keymap.json" -Force
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Zed\tasks.json" -Target "$dotfiles\zed\tasks.json" -Force
```

### Symlink (Linux / macOS)

```bash
dotfiles="$HOME/enlistments/dotfiles"

ln -sf "$dotfiles/zed/settings.json" ~/.config/zed/settings.json
ln -sf "$dotfiles/zed/keymap.json" ~/.config/zed/keymap.json
ln -sf "$dotfiles/zed/tasks.json" ~/.config/zed/tasks.json
```

### Extensions

Install via the command palette (`Ctrl+Shift+P` → `zed: extensions`):

| Extension | Purpose |
|---|---|
| **C#** | C# language support (OmniSharp/Roslyn) |
| **Java** | Java language support |
| **Tokyo Night** | Color theme (if not bundled) |

---

## Files Overview

| File | Purpose |
|---|---|
| `settings.json` | Core editor settings — vim mode, theme, fonts, formatting, language overrides |
| `keymap.json` | Custom keybindings — LazyVim-style leader keys, project panel shortcuts |
| `tasks.json` | Build & test tasks — Maven, Gradle, dotnet |

---

## Vim Mode

Vim mode is enabled globally. Zed's vim emulation includes motions, text objects, visual/block mode, macros, and surround (`ys`/`cs`/`ds`). It uses Zed's Tree-sitter and LSP integration for semantic-aware navigation.

### Built-in Vim Shortcuts (Zed defaults)

These work out of the box — no keymap.json needed:

| Action | Keys |
|---|---|
| Go to definition | `g d` |
| Go to type definition | `g y` |
| Go to implementation | `g I` |
| Go to all references | `g A` |
| Find symbol in file | `g s` |
| Find symbol in project | `g S` |
| Show hover/error info | `g h` |
| Code actions | `g .` |
| Next/prev diagnostic | `] d` / `[ d` |
| Next/prev git change | `] c` / `[ c` |
| Surround (yank) | `y s <motion> <char>` |
| Surround (change) | `c s <old> <new>` |
| Surround (delete) | `d s <char>` |
| Comment toggle | `g c c` (normal) / `g c` (visual) |
| Add cursor on next match | `g l` |
| Add cursor on all matches | `g a` |

---

## Custom Keybindings

All custom bindings are in `keymap.json`. They follow the LazyVim `<space>` leader convention.

### Normal Mode — Leader Bindings

| Keys | Action | LazyVim Equivalent |
|---|---|---|
| `Space e` | Toggle file explorer (left dock) | `<leader>e` |
| `Space f f` | Find file by name | `<leader>ff` (Telescope) |
| `Space f r` | Open recent projects | `<leader>fr` |
| `Space /` | Project-wide search | `<leader>/` (grep) |
| `Space w` | Save file | `<leader>w` |
| `Space b d` | Close current buffer | `<leader>bd` |
| `Space x x` | Open diagnostics panel | `<leader>xx` (Trouble) |
| `Space t t` | Toggle terminal | `<C-/>` |
| `Space c a` | Code actions | `<leader>ca` |
| `Space c r` | Rename symbol | `<leader>cr` |
| `Space c f` | Format file | `<leader>cf` |
| `Space g r` | Find all references | `<leader>gr` |
| `Space -` | Split horizontally | `<leader>-` |
| `Space \|` | Split vertically | `<leader>\|` |

### Normal Mode — Buffer Navigation

| Keys | Action |
|---|---|
| `Shift-H` | Previous buffer/tab |
| `Shift-L` | Next buffer/tab |

### Insert Mode

| Keys | Action |
|---|---|
| `j k` | Exit insert mode (→ Normal) |

### Project Panel (File Explorer)

When the project panel is focused:

| Key | Action | Neo-tree Equivalent |
|---|---|---|
| `a` | New file | `a` |
| `A` | New directory | `A` |
| `r` | Rename | `r` |
| `d` | Delete | `d` |
| `x` | Cut | `x` |
| `c` | Copy | `c` |
| `p` | Paste | `p` |

Navigate with `h` / `j` / `k` / `l` as expected in vim mode.

---

## Settings Highlights

### Appearance

- **Theme:** Tokyo Night
- **Font:** JetBrainsMono Nerd Font @ 14px (buffer, UI, and terminal)
- **Relative line numbers:** enabled (essential for vim `{count}j/k` motions)
- **Whitespace:** rendered visually (`show_whitespaces: "all"`)

### Editor Behavior

- **Format on save:** enabled globally (disabled for Java — see below)
- **Trim trailing whitespace:** on save
- **Ensure final newline:** on save
- **Default tab size:** 2 spaces
- **Scroll beyond last line:** off

### Terminal

- **Shell:** `pwsh` (PowerShell 7+), matching the Neovim terminal config
- **Font:** same as editor (JetBrainsMono Nerd Font @ 14px)

### AI / Copilot

- **Edit predictions:** GitHub Copilot (matching `lazyvim.plugins.extras.ai.copilot-native`)
- Zed's built-in AI agent panel can use additional providers (OpenAI, Anthropic, etc.) — configure via the command palette if desired

### Language Overrides

#### Java

- **Tab size:** 4 spaces (matching `ftplugin/java.lua`)
- **Format on save:** disabled (matching `vim.b.autoformat = false`)
- **Formatter:** `google-java-format --aosp` via external command (matching `plugins/java.lua` conform.nvim config)

#### C\#

- **Tab size:** 4 spaces (Roslyn/dotnet convention)
- **Format on save:** uses global default (on)

---

## Tasks

Run tasks via the command palette (`Ctrl+Shift+P` → `task: spawn`) or the tasks menu.

| Task | Command | Notes |
|---|---|---|
| Java: Build (Maven) | `mvn compile` | Hides terminal on success |
| Java: Test (Maven) | `mvn test` | Keeps terminal visible |
| Java: Build (Gradle) | `./gradlew build` | Hides terminal on success |
| C#: Build (dotnet) | `dotnet build` | Hides terminal on success |
| C#: Test (dotnet) | `dotnet test` | Keeps terminal visible |
| C#: Run (dotnet) | `dotnet run` | Keeps terminal visible |

All tasks save open files before running.

---

## Neovim Feature Parity Notes

Some Neovim/LazyVim features don't have direct Zed equivalents:

| Neovim Feature | Zed Status |
|---|---|
| Auto-fold import blocks (`autocmds.lua`) | Not supported — Zed doesn't have user-defined autocmds |
| Octo.nvim (GitHub PR reviews) | Use Zed's built-in Git panel or the `gh` CLI |
| Telescope fuzzy finder | Zed's built-in file finder (`Space f f`) and search (`Space /`) cover the core use cases |
| Neo-tree file explorer | Project panel with our custom keys is functionally equivalent |
| LazyVim plugin manager | Zed uses its own extension system — install via the command palette |

---

## Useful Zed Commands

Open the command palette with `Ctrl+Shift+P` (or `:` in vim normal mode for ex commands):

| Command | What it does |
|---|---|
| `zed: open settings` | Open settings editor (searchable UI) |
| `zed: open settings file` | Open `settings.json` directly |
| `zed: open keymap` | Open `keymap.json` directly |
| `zed: extensions` | Browse and install extensions |
| `zed: open default settings` | View all available settings with defaults |
| `workspace: toggle vim mode` | Toggle vim mode on/off |
| `dev: open key context view` | Debug keybinding context issues |

---

## Customizing Further

- **Settings reference:** Open command palette → `zed: open default settings` to see every option
- **Keymap reference:** See [Zed Key Bindings docs](https://zed.dev/docs/key-bindings)
- **Vim mode docs:** See [Zed Vim Mode docs](https://zed.dev/docs/vim)
- **Tasks docs:** See [Zed Tasks docs](https://zed.dev/docs/tasks)
