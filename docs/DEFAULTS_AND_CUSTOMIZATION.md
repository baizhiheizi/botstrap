# Defaults & customization

This guide explains **default** behavior when you skip or cannot use the TUI, **what Phase 3 applies** on a fresh machine, and **how to customize** Botstrap for yourself or for automation. For a post-install inventory and everyday usage, see [After install](./AFTER_INSTALL.md). For the exact `configs/` → home path table, see [Configuration file map](./CONFIGURATION.md).

## Phase 2 defaults (no gum or non-interactive run)

When **gum** is not on `PATH`, Phase 2 (`install/phase-2-tui.sh` / `phase-2-tui.ps1`) exports **safe defaults** and exits without prompts so CI and agents do not hang:

| Variable | Default when gum is missing |
|----------|-----------------------------|
| `BOTSTRAP_GIT_NAME` / `BOTSTRAP_GIT_EMAIL` | Empty unless already set in the environment. |
| `BOTSTRAP_GIT_ALIASES` | All catalog entries with **`default: true`** when **`configs/git/aliases.yaml`** has **`defaults.enabled: true`**, unless **`git-aliases.env`** already has **`selected=`** (reconfigure). Set to **`none`** to skip. |
| `BOTSTRAP_EDITOR` | `none` |
| `BOTSTRAP_LANGUAGES` | Empty (no optional language installs from TUI). |
| `BOTSTRAP_DATABASES` | Empty. |
| `BOTSTRAP_AI_TOOLS` | Empty. |
| `BOTSTRAP_THEME` | `catppuccin` |
| `BOTSTRAP_OPTIONAL_APPS` | Empty. |

You can **pre-set any `BOTSTRAP_*`** before running `install.sh`, `install.ps1`, or individual phases to force choices without the TUI.

## Phase 3 defaults (what gets applied)

Phase 3 copies or merges from **`configs/`** and runs optional installs from **`registry/optional.yaml`**. Typical defaults:

- **Git:** `configs/git/gitconfig` is copied to **`~/.gitconfig`** only if that file **does not** already exist. Global **`user.name`** / **`user.email`** are set from **`BOTSTRAP_GIT_NAME`** / **`BOTSTRAP_GIT_EMAIL`** when non-empty. **Git shortcuts** (`git st`, `git co`, …) from **`configs/git/aliases.yaml`** are written to **`~/.config/botstrap/git-aliases`** and included from **`~/.gitconfig`** when selected in Phase 2 (or when **`BOTSTRAP_GIT_ALIASES`** is preset).
- **Git ignore:** `gitignore_global` is copied and **`core.excludesfile`** is pointed at it when Git is available.
- **Starship:** `configs/shell/prompt.toml` → **`~/.config/starship.toml`** (overwrites when the repo file exists).
- **Shell rc files:** `aliases` and `functions` are appended **once** inside `# botstrap aliases` / `# botstrap functions` blocks to **`~/.zshrc`** and **`~/.bashrc`** (Unix). The PATH snippet sources **`~/.config/botstrap/env.sh`**.
- **`env.sh`:** Regenerated each Phase 3 run; sets **`BOTSTRAP_ROOT`** and prepends **`$BOTSTRAP_ROOT/bin`** to **`PATH`** (duplicate-safe).
- **Editor templates:** Copied only when **`BOTSTRAP_EDITOR`** is `cursor`, `vscode`, or `neovim` (see [Configuration file map](./CONFIGURATION.md)). **Neovim** and LazyVim are installed via the **core** tool **`neovim`** when it appears in **`BOTSTRAP_CORE_TOOLS`**; the optional Editor group covers Cursor, VS Code, and Zed only.
- **Agent samples:** `configs/agent/*` → **`~/.config/botstrap/agent/*.sample`** only (not live Cursor/Claude paths unless you copy them).
- **Windows:** Each managed PowerShell profile (Windows PowerShell 5.1, **`pwsh`**, and the current **`$PROFILE`** when different) gets the same marker-guarded blocks for PATH, starship, zoxide, and aliases as implemented in Phase 3; there is no Unix-style **`env.sh`** on native Windows.

Phase 3 also writes **`theme.env`** and **`editor.env`** under **`~/.config/botstrap/`** (or Windows equivalent).

## How to customize

### 1. `botstrap reconfigure`

Runs Phase 2 + Phase 3 again from your checkout. Use this after changing your mind about optional tools or after pulling updates that touch `configs/`.

### 2. Edit templates in the clone

Change files under **`configs/`** in **`BOTSTRAP_ROOT`**, then run **`botstrap reconfigure`** or Phase 3 only. The mapping of repo paths to home paths is in [Configuration file map](./CONFIGURATION.md).

### 3. CI and automation

Export **`BOTSTRAP_*`** variables before the orchestrator or before sourcing Phase 2 + 3. Full list and meanings: [Reference — Phase 2 selection variables](./REFERENCE.md#phase-2-selection-variables-unix). Windows OS tuning variables: [Cross-platform notes](./CROSS_PLATFORM.md).

### 4. Manual edits in your home directory

- Prefer editing **`~/.config/...`** files directly for Starship, editor configs, and Git excludes when you do not want to flow changes through the repo.
- **Git aliases:** edit **`~/.config/botstrap/git-aliases`** directly, or run **`botstrap reconfigure`** to change the Phase 2 selection. To add custom aliases outside Botstrap, set them in **`~/.gitconfig`** (not in the include file) so reconfigure does not overwrite them.
- For **`~/.zshrc`** / **`~/.bashrc`**, avoid duplicating Botstrap blocks: either edit **outside** the `# botstrap …` sections or adjust **`configs/shell/*`** in the clone and re-run Phase 3 so a single marked block stays canonical.

### 5. Fork or extend the registry

Add or change tools in **`registry/prerequisites.yaml`**, **`registry/core.yaml`**, or **`registry/optional.yaml`**. Schema and conventions: [Registry specification](./REGISTRY_SPEC.md).

### Windows-only OS tuning

Phase 0b reads **`configs/os/windows.yaml`**. Elevation, skips, and UTF-8 toggles are documented in [Cross-platform notes](./CROSS_PLATFORM.md).

## Related

- [After install](./AFTER_INSTALL.md) — what is installed and how to use it.
- [Reference](./REFERENCE.md) — CLI, boot variables, artifacts.
- [Configuration file map](./CONFIGURATION.md) — template destinations.
