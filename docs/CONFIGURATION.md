# Configuration file map

This page maps **repository paths** under **`configs/`** to **destination paths** on your machine. **Phase 3** (`install/phase-3-configure.sh` on Unix; `install/phase-3-configure.ps1` on Windows) copies or merges them according to TUI selections and fixed rules.

For **defaults**, **automation env vars**, and **how to customize** (reconfigure, fork, rc file markers), see [Defaults & customization](./DEFAULTS_AND_CUSTOMIZATION.md). For **what is installed** and **how to use** core and optional tools, see [After install](./AFTER_INSTALL.md). For environment variables that drive Phase 3, see [Reference](./REFERENCE.md). For Windows-only OS policy tuning, see [Cross-platform notes](./CROSS_PLATFORM.md) (`configs/os/windows.yaml`).

## `configs/git/`

| Repository file | Destination / effect |
|-----------------|----------------------|
| `configs/git/gitconfig` | Copied to **`~/.gitconfig`** only when that file does **not** already exist (Unix Phase 3). |
| `configs/git/gitignore_global` | Copied to **`~/.gitignore_global`**; `git config --global core.excludesfile` set to that path when Git is available. |
| `configs/git/aliases.yaml` | Catalog of recommended git aliases (not copied verbatim). Phase 2 uses it for preview and multi-select; Phase 3 writes selected aliases to **`~/.config/botstrap/git-aliases`** and adds a **`[include]`** in **`~/.gitconfig`** (marker **`# botstrap git-aliases`**). |

Global **`user.name`** and **`user.email`** are set from **`BOTSTRAP_GIT_NAME`** and **`BOTSTRAP_GIT_EMAIL`** when non-empty (not from static files). Git alias selection is driven by **`BOTSTRAP_GIT_ALIASES`** (see [Reference — Phase 2 selection variables](./REFERENCE.md#phase-2-selection-variables-unix)).

## `configs/shell/`

| Repository file | Destination / effect |
|-----------------|----------------------|
| `configs/shell/prompt.toml` | Fallback only: copied to **`~/.config/starship.toml`** when no theme bundle provides **`starship.toml`** (see **`themes/`** below). |
| `configs/shell/aliases` | Appended once to **`~/.zshrc`** and **`~/.bashrc`** inside a block marked `# botstrap aliases`. |
| `configs/shell/functions` | Appended once to **`~/.zshrc`** and **`~/.bashrc`** inside a block marked `# botstrap functions`. |

## `configs/editor/`

Applied when **`BOTSTRAP_EDITOR`** matches (Unix Phase 3):

| Editor choice | Repository file | Destination |
|---------------|-----------------|-------------|
| `cursor` | `configs/editor/cursor-settings.json` | `~/.cursor/settings.json` (then shallow-merge keys from **`themes/<BOTSTRAP_THEME>/editor.json`** on Unix when **`jq`** is available; Windows merges via PowerShell) |
| `vscode` | `configs/editor/vscode.json` | `~/.config/Code/User/settings.json` (same theme merge as Cursor) |
| `neovim` | LazyVim starter ([`LazyVim/starter`](https://github.com/LazyVim/starter)) via `install/modules/lazyvim` when **`neovim`** is in **`BOTSTRAP_CORE_TOOLS`** (core registry `post_install`); Phase 3 copies `configs/editor/neovim/init.lua` only if `lua/config/lazy.lua` is missing | macOS/Linux: `~/.config/nvim`. Windows: `%LOCALAPPDATA%\nvim` (typically `~/AppData/Local/nvim`). |

Other editor values skip these copies.

## `configs/agent/`

Copied as **samples** only (Unix Phase 3):

| Repository file | Destination |
|-----------------|-------------|
| `configs/agent/AGENTS.md` | `~/.config/botstrap/agent/AGENTS.md.sample` |
| `configs/agent/cursorrules` | `~/.config/botstrap/agent/cursorrules.sample` |
| `configs/agent/claude-config.json` | `~/.config/botstrap/agent/claude-config.json.sample` |

Rename or merge into project-specific locations as needed; Botstrap does not overwrite live Cursor or Claude config paths by default.

## `configs/os/`

| Repository file | Consumer |
|-----------------|----------|
| `configs/os/windows.yaml` | **Phase 0b** on Windows (`install/phase-0b-os-tune.ps1` + `lib/os-tune-windows.ps1`). |

## Generated state (not under `configs/` in repo)

Phase 3 also writes:

- **`~/.config/botstrap/theme.env`** — `theme=<value>`
- **`~/.config/botstrap/editor.env`** — `editor=<value>`
- **`~/.config/botstrap/git-aliases.env`** — `selected=` and `managed=` alias id lists
- **`~/.config/botstrap/git-aliases`** — generated `[alias]` fragment included from **`~/.gitconfig`**

## `themes/`

Phase 3 uses **`BOTSTRAP_THEME`** (from the TUI or env; persisted in **`theme.env`**) to pick a folder **`themes/<id>/`** where **`<id>`** is one of **`catppuccin`**, **`tokyo-night`**, **`gruvbox`**, **`nord`**, **`rose-pine`** (see **`registry/optional.yaml`**).

| File | Effect |
|------|--------|
| `themes/<id>/starship.toml` | When present, copied to **`~/.config/starship.toml`** (Windows: **`%USERPROFILE%\.config\starship.toml`**). |
| `themes/<id>/editor.json` | Optional. When **`BOTSTRAP_EDITOR`** is **`cursor`** or **`vscode`**, its keys are merged on top of the repo editor template after the base copy (shallow object merge). Typical key: **`workbench.colorTheme`** — install the matching color-theme extension in the editor if the theme is not built in. |

If **`themes/<id>/starship.toml`** is missing, Phase 3 falls back to **`configs/shell/prompt.toml`**.

## Optional tools and themes

Phase 3 installs **selected core** from **`registry/core.yaml`** and selections from **`registry/optional.yaml`** (via **`lib/pkg`**), not only file copies from **`configs/`**. Theme **registry** rows log selection; **assets** are applied from **`themes/<id>/`** as above. See [Registry specification](./REGISTRY_SPEC.md) and [Architecture](./ARCHITECTURE.md).

## Related

- [Defaults & customization](./DEFAULTS_AND_CUSTOMIZATION.md) — defaults and customization paths.
- [After install](./AFTER_INSTALL.md) — installed stack and usage.
- [Introduction](./INTRODUCTION.md) — where Phase 3 fits in the install story.
- [Getting started](./GETTING_STARTED.md) — running the installer.
