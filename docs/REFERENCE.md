# Reference

Operational facts: **CLI**, **environment variables**, and **artifacts** Botstrap creates or expects. Behavior described here matches the shell and PowerShell sources in the repository. For a post-install inventory and **`botstrap doctor`** behavior (core vs optional verification), see [After install](./AFTER_INSTALL.md). For defaults and customization workflows, see [Defaults & customization](./DEFAULTS_AND_CUSTOMIZATION.md).

## `bin/botstrap` CLI

**Unix / Git Bash:** **`bin/botstrap`** (Bash) resolves the repository root as the parent of **`bin/`** and does **not** read `BOTSTRAP_HOME` unless you set **`BOTSTRAP_ROOT`** for subprocesses yourself.

**Native Windows PowerShell:** **`bin/botstrap.ps1`** exposes the same subcommands and runs **`install/phase-2-tui.ps1`**, **`install/phase-3-configure.ps1`**, **`install/phase-4-verify.ps1`**, and **`install/uninstall.ps1`** for **`reconfigure`**, **`doctor`**, and **`uninstall`**. It does **not** invoke Bash for those phases.

| Command | Behavior |
|---------|----------|
| `botstrap version` | Prints `botstrap <semver>` from the **`version`** file at repo root, or `unknown` if missing. |
| `botstrap self-update` | Runs **`git pull --ff-only`** in the repo root (same as repo-only refresh). Requires **`git`**. |
| `botstrap update` | **Interactive (TTY + `gum`):** **`gum choose`** among **Botstrap repo only**, **Installed tools only**, **Both**, or **Cancel**. **Non-interactive, no flags:** repo-only pull (backward compatible) and prints a one-line hint about **`--tools`**, **`--all`**, and **`self-update`**. **Flags:** **`--self`** — git pull only; **`--tools`** — run **`install/update-tools.sh`** (Bash) or **`install/update-tools.ps1`** (PowerShell) to upgrade **prerequisites**, **selected core**, and **persisted optional** selections per registry **`update`** snippets; **`--all`** — self then tools. Does **not** re-run full Phase 3 except what each **`update`** snippet does. |
| `botstrap reconfigure` | **Bash:** sets **`BOTSTRAP_ROOT`**, runs **`lib/detect`**, then sources **`install/phase-2-tui.sh`** and **`install/phase-3-configure.sh`** only. **PowerShell:** sets **`BOTSTRAP_ROOT`**, dot-sources **`install/phase-2-tui.ps1`** and **`install/phase-3-configure.ps1`**. |
| `botstrap doctor` | **Bash:** prints a short **status** header (`BOTSTRAP_ROOT`, semver, optional git head, whether **`~/.config/botstrap/env.sh`** exists), then runs **`install/phase-4-verify.sh`**. **PowerShell:** similar header (whether the **`# botstrap PATH`** hook is present in **each** known profile path—see Windows Phase 3 artifacts), then dot-sources **`install/phase-4-verify.ps1`**. Exits **0** if every verify passes, **1** if **`yq`** is missing or any verify fails. |
| `botstrap uninstall` | Removes **Phase 3 shell integration** and **Botstrap-managed git aliases** (see **`install/uninstall.sh`** / **`install/uninstall.ps1`**). **Unix:** strips **`# botstrap PATH`**, **`# botstrap aliases`**, and **`# botstrap functions`** blocks from **`~/.zshrc`** and **`~/.bashrc`**, removes the **`# botstrap git-aliases`** **`[include]`** block from **`~/.gitconfig`**, deletes **`~/.config/botstrap/git-aliases`**, and deletes **`~/.config/botstrap/env.sh`**. **Windows:** removes **`# botstrap PATH`**, **`# botstrap starship`**, **`# botstrap zoxide`**, and **`# botstrap aliases`** regions from **each** PowerShell profile path Botstrap manages (same set as Phase 3), plus the git alias include and fragment as on Unix. **Does not** uninstall packages (Homebrew, apt, winget, mise, etc.) or remove other files Botstrap copied elsewhere (e.g. **`~/.config/starship.toml`**, editor settings, the rest of **`~/.gitconfig`**). With **`--purge`**, also deletes **`git-aliases.env`**. **Exit 1** if the user cancels, a guard refuses **`--remove-checkout`**, or usage is invalid. |
| `botstrap` (no arguments) | If **stdin** and **stdout** are TTYs (**Bash**) or the console is not redirected (**PowerShell**) **and** **`gum`** is on **`PATH`**, shows a **`gum choose`** menu for **`update`**, **`self-update`**, **`reconfigure`**, **`doctor`**, **`uninstall`**, **`version`**, or **`quit`** (exit **0**). Otherwise prints **usage** and exits **1**. For automation and **AI agents**, pass an explicit subcommand (e.g. **`botstrap doctor`**, **`botstrap update --all`**) instead of relying on the menu. |
| Any other first argument | Prints **usage** and exits with code **1**. |

**`botstrap uninstall` flags**

| Flag | Behavior |
|------|----------|
| *(none)* | **Interactive:** **`gum confirm`** or **`[y/N]`** when the console is a TTY. **Non-interactive:** requires **`--yes`**. |
| `--yes` | Skip prompts and run the requested uninstall steps. |
| `--purge` | After hook removal, delete **`~/.config/botstrap`** (Unix) or **`%USERPROFILE%\.config\botstrap`** (Windows). |
| `--remove-checkout` | After the above, delete the Botstrap repo root (parent of **`bin/`**). **Refused** if the path is not absolute, is **`/`** or **`$HOME`** / **`%USERPROFILE%`**, is a **drive root**, or **`$ROOT/.git`** is missing. |

## Boot and install environment variables

| Variable | Used by | Purpose |
|----------|---------|---------|
| `BOTSTRAP_HOME` | `boot.sh`, `boot.ps1` | Directory to clone or use as the Botstrap Git checkout (default: `$HOME/.botstrap` / `%USERPROFILE%\.botstrap`). |
| `BOTSTRAP_REPO` | `boot.sh`, `boot.ps1` | Git remote URL for clone (default: `https://github.com/an-lee/botstrap.git`). |
| `BOTSTRAP_BOOT_PREREQS_URL` | `boot.sh` | Optional raw HTTPS URL to **`install/boot-prereqs-git.sh`** when **`BOTSTRAP_REPO`** is not GitHub-hosted and git is missing (so boot can still source the prerequisite installer). |
| `BOTSTRAP_ROOT` | `install.sh`, phases, `bin/botstrap` | Absolute path to the Botstrap checkout containing `registry/`, `install/`, etc. Set automatically by `install.sh`; required when sourcing phases manually. |
| `BOTSTRAP_LOG_COLOR` | `lib/log.sh` (Unix only) | Set to `0` to disable color output from logging helpers (default: `1`). Useful in CI or non-terminal environments. |

## Phase 2 selection variables (Unix)

Set by **`install/phase-2-tui.sh`** (or defaults when gum is missing). Group ids are documented in that file’s header.

| Variable | Meaning |
|----------|---------|
| `BOTSTRAP_GIT_NAME` | Global Git `user.name` (Phase 3). |
| `BOTSTRAP_GIT_EMAIL` | Global Git `user.email` (Phase 3). |
| `BOTSTRAP_GIT_ALIASES` | Comma-separated alias **`id`** values from **`configs/git/aliases.yaml`** (e.g. `st,co,lg`), or **`none`** to skip. Interactive Phase 2 shows a preview and multi-select; non-interactive default: all catalog entries with **`default: true`** when **`defaults.enabled`** is true (or persisted **`selected=`** from **`git-aliases.env`** on reconfigure). |
| `BOTSTRAP_CORE_TOOLS` | Comma-separated tool **`name`** values from **`registry/core.yaml`** to install in Phase 3 (registry order). Set by the TUI (default: all names) or non-interactive defaults; may be preset for automation. |
| `BOTSTRAP_EDITOR` | One of: `cursor`, `vscode`, `neovim`, `zed`, `none`. |
| `BOTSTRAP_LANGUAGES` | Comma-separated mise-related choices: `node`, `python`, `ruby`, `go`, `rust`, `java`, `elixir`, `php`, `none`, … |
| `BOTSTRAP_DATABASES` | Comma-separated: `postgresql`, `mysql`, `redis`, `sqlite`, `none`, … |
| `BOTSTRAP_AI_TOOLS` | Comma-separated: `claude-code`, `openclaw`, `codex`, `gemini`, `ollama`, `none`, … |
| `BOTSTRAP_THEME` | One of: `catppuccin`, `tokyo-night`, `gruvbox`, `nord`, `rose-pine`. |
| `BOTSTRAP_OPTIONAL_APPS` | Comma-separated: `1password-cli`, `tailscale`, `ngrok`, `postman`, `none`, … |

Phase 3 installs **core** via **`BOTSTRAP_CORE_TOOLS`** and **`registry/core.yaml`**, then passes the remaining variables into **`lib/pkg`** helpers for **`registry/optional.yaml`**.

## Windows OS tuning variables

See [Cross-platform notes](./CROSS_PLATFORM.md) for **`BOTSTRAP_OS_TUNE`**, **`BOTSTRAP_OS_TUNE_SKIP`**, and **`BOTSTRAP_OS_TUNE_UTF8`**.

## Artifacts and side effects (Unix Phase 3)

Unless otherwise noted, paths are under **`$HOME`**.

| Action | Condition |
|--------|-----------|
| `~/.config/`, `~/.config/git/` | Created if needed. |
| `~/.gitconfig` | Copied from `configs/git/gitconfig` **only if** `~/.gitconfig` does **not** already exist. |
| Optional registry installs | Editor, languages, databases, AI tools, theme, optional apps from **`registry/optional.yaml`**. |
| `~/.config/starship.toml` | Overwritten from `configs/shell/prompt.toml` when that file exists in the repo. |
| `~/.gitignore_global` | Copied from `configs/git/gitignore_global`; `core.excludesfile` set globally. |
| Git user.name / user.email | Set from `BOTSTRAP_GIT_*` when non-empty. |
| Git aliases | Selected ids from **`BOTSTRAP_GIT_ALIASES`** written to **`~/.config/botstrap/git-aliases`**; **`~/.gitconfig`** gets a one-time **`# botstrap git-aliases`** **`[include]`** pointing at that file. Existing global aliases with the same name are skipped unless Botstrap previously managed them. |
| `~/.config/botstrap/git-aliases.env` | **`selected=`** and **`managed=`** comma-separated alias ids (Phase 3) for reconfigure TUI defaults and conflict detection. |
| `~/.zshrc`, `~/.bashrc` | Appended **once** (marker-guarded) with contents of `configs/shell/aliases`, `configs/shell/functions`, and `configs/shell/env_path_snippet.bash` when those repo files exist. The PATH snippet sources **`~/.config/botstrap/env.sh`**. |
| `~/.config/botstrap/core-tools.env` | **`core_tools=`** comma-separated list (persisted Phase 3) for **`botstrap doctor`** / reconfigure default core selection when **`BOTSTRAP_CORE_TOOLS`** is not set in the shell. |
| `~/.config/botstrap/optional-selections.env` | **`languages=`**, **`databases=`**, **`ai_tools=`**, **`optional_apps=`** (Phase 3) for **`botstrap update --tools`** and TUI **`--selected`** defaults on reconfigure. |
| `~/.config/botstrap/env.sh` | **Unix Phase 3:** sets **`BOTSTRAP_ROOT`** and prepends **`$BOTSTRAP_ROOT/bin`** to **`PATH`** (duplicate-safe). Regenerated each Phase 3 run. |
| Editor configs | **cursor:** `~/.cursor/settings.json` from `configs/editor/cursor-settings.json`. **vscode:** `~/.config/Code/User/settings.json` from `configs/editor/vscode.json`. **neovim:** LazyVim under `~/.config/nvim` via core tool **`neovim`** (`install/modules/lazyvim.sh`); Phase 3 copies `configs/editor/neovim/init.lua` only if `~/.config/nvim/lua/config/lazy.lua` is missing. |
| `~/.config/botstrap/theme.env`, `editor.env` | Small key=value files for theme and editor. |
| `~/.config/botstrap/agent/*.sample` | Copies of `configs/agent/AGENTS.md`, `cursorrules`, `claude-config.json` as **`.sample`** files (not live agent config unless you copy them). |

## Artifacts and side effects (Windows Phase 3)

Paths use **`%USERPROFILE%`** where relevant.

| Action | Condition |
|--------|-----------|
| **`%USERPROFILE%\.config\botstrap\core-tools.env`** | **`core_tools=`** persisted list (Phase 3) for **`doctor`** / TUI defaults when **`BOTSTRAP_CORE_TOOLS`** is unset. |
| **`%USERPROFILE%\.config\botstrap\optional-selections.env`** | **`languages=`**, **`databases=`**, **`ai_tools=`**, **`optional_apps=`** for **`update --tools`** and reconfigure TUI defaults. |
| Git aliases | Same as Unix: **`%USERPROFILE%\.config\botstrap\git-aliases`**, include block in **`%USERPROFILE%\.gitconfig`**, **`git-aliases.env`** for persistence. |
| Editor configs (**`BOTSTRAP_EDITOR`**) | **cursor** / **vscode:** under **`%USERPROFILE%`** as in [Configuration file map](./CONFIGURATION.md). **neovim:** **`%LOCALAPPDATA%\nvim`** — LazyVim from core tool **`neovim`** (**`install/modules/lazyvim.ps1`**); minimal **`init.lua`** only when **`lua\config\lazy.lua`** is missing. |
| Zellij **`config.kdl`** (`default_shell`) | When **`zellij`** is in **`BOTSTRAP_CORE_TOOLS`**: Phase 3 runs **`install/modules/zellij.ps1`** which sets **`default_shell`** to the resolved `pwsh`/`powershell` path in **`config.kdl`** (location from `zellij setup --check`; fallback **`%USERPROFILE%\.config\zellij\config.kdl`**). Marker comment `// botstrap: default_shell (Windows)` guards repeated runs. |
| PowerShell **profiles** (dual host): **`Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`** (Windows PowerShell 5.1) and **`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`** (**`pwsh`** 7+), plus **`$PROFILE`** when it differs (e.g. VS Code host) | Each file is updated **once** (marker-guarded) with the same blocks: **`# botstrap PATH`** sets **`$env:BOTSTRAP_ROOT`**, prepends **`$BOTSTRAP_ROOT\bin`** to **`$env:PATH`**, and defines **`function Global:botstrap`** invoking **`bin\botstrap.ps1`**. Also **`# botstrap starship`**, **`# botstrap zoxide`**, and **`# botstrap aliases`** when missing. |

There is **no** **`~/.config/botstrap/env.sh`** on native Windows; the profile block is the shell hook for the **`botstrap`** command.

## Phase 4 verification

- **Unix (`install/phase-4-verify.sh`):** Verifies every tool in **`registry/prerequisites.yaml`**, then **selected** core: if **`BOTSTRAP_CORE_TOOLS`** is set in the environment (including empty), uses that; else if **`~/.config/botstrap/core-tools.env`** contains **`core_tools=`**, uses its value; else verifies **all** names in **`registry/core.yaml`** (legacy installs without persistence). Warns per failure; exits **1** if **`yq`** is missing or any run verify fails. **Optional** TUI selections are **not** verified on Unix.
- **Windows (`install/phase-4-verify.ps1`):** Same **prerequisites** + **selected core** resolution via **`Get-BotstrapCoreToolNamesForVerify`**, then verifies **optional** groups when **`BOTSTRAP_*`** variables are set (see [After install](./AFTER_INSTALL.md)).

## Related

- [After install](./AFTER_INSTALL.md) — installed stack, `doctor`, persisted selections.
- [Defaults & customization](./DEFAULTS_AND_CUSTOMIZATION.md) — defaults and how to change config.
- [Configuration file map](./CONFIGURATION.md) — template tree under `configs/` → home paths.
- [Architecture](./ARCHITECTURE.md) — phase scripts and `lib/` overview.
