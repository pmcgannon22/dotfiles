# dotfiles

Personal configuration files, portable across machines.

## Contents

| Path | Description | Symlink Target |
|---|---|---|
| `nvim/` | Neovim (LazyVim) configuration | `~/.config/nvim/` or `%LOCALAPPDATA%\nvim\` |
| `zed/` | Zed editor configuration | `%APPDATA%\Zed\` (Windows) or `~/.config/zed/` (Linux/macOS) |
| `.bashrc` | Bash configuration | `~/.bashrc` |
| `.zshrc` | Zsh configuration | `~/.zshrc` (managed by `install-zsh-setup.sh`) |
| `.gitconfig` | Git configuration | `~/.gitconfig` |
| `.vimrc` | Vim configuration | `~/.vimrc` |
| `vscode.settings.json` | VS Code settings reference | Manual copy to VS Code settings |

## Zed Editor Setup

The `zed/` folder contains configuration for the [Zed editor](https://zed.dev/) with Vim mode enabled, mirroring the Neovim/LazyVim workflow.

### Files

- **`settings.json`** — Core settings: Vim mode, Tokyo Night theme, relative line numbers, format on save, terminal (pwsh), language overrides for Java and C#
- **`keymap.json`** — LazyVim-style `<space>` leader bindings, `jk` insert escape, Neo-tree-style project panel keys
- **`tasks.json`** — Build/test tasks for Java (Maven, Gradle) and C# (.NET)

### Symlink Setup (Windows)

From an **elevated PowerShell** prompt:

```powershell
# Create symlinks (adjust source path to your dotfiles location)
$dotfiles = "C:\enlistments\dotfiles"

New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Zed\settings.json" -Target "$dotfiles\zed\settings.json" -Force
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Zed\keymap.json" -Target "$dotfiles\zed\keymap.json" -Force
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Zed\tasks.json" -Target "$dotfiles\zed\tasks.json" -Force
```

### Symlink Setup (Linux / macOS)

```bash
dotfiles="$HOME/enlistments/dotfiles"

ln -sf "$dotfiles/zed/settings.json" ~/.config/zed/settings.json
ln -sf "$dotfiles/zed/keymap.json" ~/.config/zed/keymap.json
ln -sf "$dotfiles/zed/tasks.json" ~/.config/zed/tasks.json
```

### Recommended Extensions

Install these via Zed's extension marketplace (`zed: extensions` in command palette):

- **C#** — C# language support (OmniSharp/Roslyn)
- **Java** — Java language support
- **Tokyo Night** — Theme (if not already bundled)
