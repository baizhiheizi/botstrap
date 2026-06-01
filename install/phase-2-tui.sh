#!/usr/bin/env bash
# Phase 2: gum-powered TUI. Exports BOTSTRAP_* env vars for later phases.
# Group ids: core (registry/core.yaml names), editor, languages, databases, ai_tools, theme, optional_apps
# BOTSTRAP_CORE_TOOLS: comma-separated names from registry/core.yaml (prerequisites are Phase 0 only).
set -euo pipefail

: "${BOTSTRAP_ROOT:?BOTSTRAP_ROOT must be set}"
# shellcheck source=lib/log.sh
source "${BOTSTRAP_ROOT}/lib/log.sh"
# shellcheck source=lib/bash-compat.sh
source "${BOTSTRAP_ROOT}/lib/bash-compat.sh"

if ! command -v gum &>/dev/null; then
  botstrap_log_warn "gum not found; exporting safe defaults for non-interactive runs."
  export BOTSTRAP_GIT_NAME="${BOTSTRAP_GIT_NAME:-}"
  export BOTSTRAP_GIT_EMAIL="${BOTSTRAP_GIT_EMAIL:-}"
  _all_core_csv="$(yq -r '.tools[].name' "${BOTSTRAP_ROOT}/registry/core.yaml" | paste -sd, -)"
  export BOTSTRAP_CORE_TOOLS="${BOTSTRAP_CORE_TOOLS:-${_all_core_csv}}"
  _opt_sel="${HOME}/.config/botstrap/optional-selections.env"
  _ed_env="${HOME}/.config/botstrap/editor.env"
  _th_env="${HOME}/.config/botstrap/theme.env"
  if [[ -z "${BOTSTRAP_EDITOR:-}" && -f "${_ed_env}" ]]; then
    export BOTSTRAP_EDITOR="$(grep -m1 '^editor=' "${_ed_env}" 2>/dev/null | sed 's/^editor=//' || true)"
  fi
  export BOTSTRAP_EDITOR="${BOTSTRAP_EDITOR:-none}"
  if [[ -z "${BOTSTRAP_LANGUAGES:-}" && -f "${_opt_sel}" ]]; then
    export BOTSTRAP_LANGUAGES="$(grep -m1 '^languages=' "${_opt_sel}" 2>/dev/null | sed 's/^languages=//' || true)"
  fi
  export BOTSTRAP_LANGUAGES="${BOTSTRAP_LANGUAGES:-}"
  if [[ -z "${BOTSTRAP_DATABASES:-}" && -f "${_opt_sel}" ]]; then
    export BOTSTRAP_DATABASES="$(grep -m1 '^databases=' "${_opt_sel}" 2>/dev/null | sed 's/^databases=//' || true)"
  fi
  export BOTSTRAP_DATABASES="${BOTSTRAP_DATABASES:-}"
  if [[ -z "${BOTSTRAP_AI_TOOLS:-}" && -f "${_opt_sel}" ]]; then
    export BOTSTRAP_AI_TOOLS="$(grep -m1 '^ai_tools=' "${_opt_sel}" 2>/dev/null | sed 's/^ai_tools=//' || true)"
  fi
  export BOTSTRAP_AI_TOOLS="${BOTSTRAP_AI_TOOLS:-}"
  if [[ -z "${BOTSTRAP_THEME:-}" && -f "${_th_env}" ]]; then
    export BOTSTRAP_THEME="$(grep -m1 '^theme=' "${_th_env}" 2>/dev/null | sed 's/^theme=//' || true)"
  fi
  export BOTSTRAP_THEME="${BOTSTRAP_THEME:-catppuccin}"
  if [[ -z "${BOTSTRAP_OPTIONAL_APPS:-}" && -f "${_opt_sel}" ]]; then
    export BOTSTRAP_OPTIONAL_APPS="$(grep -m1 '^optional_apps=' "${_opt_sel}" 2>/dev/null | sed 's/^optional_apps=//' || true)"
  fi
  export BOTSTRAP_OPTIONAL_APPS="${BOTSTRAP_OPTIONAL_APPS:-}"
  # shellcheck source=lib/git-aliases.sh
  source "${BOTSTRAP_ROOT}/lib/git-aliases.sh"
  _git_aliases_env="$(botstrap_git_aliases_env_path)"
  if [[ -z "${BOTSTRAP_GIT_ALIASES:-}" ]]; then
    if [[ -f "${_git_aliases_env}" ]]; then
      _ga_ln="$(grep -m1 '^selected=' "${_git_aliases_env}" 2>/dev/null || true)"
      if [[ -n "${_ga_ln}" ]]; then
        export BOTSTRAP_GIT_ALIASES="${_ga_ln#selected=}"
      else
        export BOTSTRAP_GIT_ALIASES="$(botstrap_git_aliases_default_csv)"
      fi
    else
      export BOTSTRAP_GIT_ALIASES="$(botstrap_git_aliases_default_csv)"
    fi
  fi
  exit 0
fi

gum style --border rounded --padding "1 2" --foreground 212 "Botstrap" "" "Cross-platform developer bootstrap."

_git_name_placeholder='Git user name'
if [[ -z "${GIT_AUTHOR_NAME:-}" ]]; then
  _git_global_name="$(git config --global --get user.name 2>/dev/null || true)"
  [[ -n "${_git_global_name}" ]] && _git_name_placeholder="${_git_global_name}"
fi
_git_email_placeholder='Git email'
if [[ -z "${GIT_AUTHOR_EMAIL:-}" ]]; then
  _git_global_email="$(git config --global --get user.email 2>/dev/null || true)"
  [[ -n "${_git_global_email}" ]] && _git_email_placeholder="${_git_global_email}"
fi

_git_name_args=()
if [[ -n "${GIT_AUTHOR_NAME:-}" ]]; then
  _git_name_args=(--value "${GIT_AUTHOR_NAME}")
fi
# shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
export BOTSTRAP_GIT_NAME="${BOTSTRAP_GIT_NAME:-$(gum input --placeholder "${_git_name_placeholder}" ${_git_name_args[@]+"${_git_name_args[@]}"})}"

_git_email_args=()
if [[ -n "${GIT_AUTHOR_EMAIL:-}" ]]; then
  _git_email_args=(--value "${GIT_AUTHOR_EMAIL}")
fi
# shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
export BOTSTRAP_GIT_EMAIL="${BOTSTRAP_GIT_EMAIL:-$(gum input --placeholder "${_git_email_placeholder}" ${_git_email_args[@]+"${_git_email_args[@]}"})}"

# shellcheck source=lib/git-aliases.sh
source "${BOTSTRAP_ROOT}/lib/git-aliases.sh"
if [[ -z "${BOTSTRAP_GIT_ALIASES:-}" ]]; then
  _git_alias_env_file="$(botstrap_git_aliases_env_path)"
  _git_alias_labels=()
  botstrap_read_lines_to_array _git_alias_labels < <(botstrap_git_aliases_choose_labels)
  if [[ ${#_git_alias_labels[@]} -gt 0 ]]; then
    _git_alias_preview=()
    botstrap_read_lines_to_array _git_alias_preview < <(botstrap_git_aliases_preview_lines)
    _git_alias_preview_text=""
    if [[ ${#_git_alias_preview[@]} -gt 0 ]]; then
      _git_alias_preview_text="$(printf '%s\n' "${_git_alias_preview[@]}")"
    fi
    gum style --border normal --padding "0 1" --foreground 212 \
      "Git shortcuts" "" \
      "Run git st, git co, and similar aliases from configs/git/aliases.yaml." "" \
      "${_git_alias_preview_text}"

    if gum confirm "Install git shortcuts? (git st, git co, …)"; then
      _git_alias_gum_args=()
      _git_alias_seed_csv=""
      if [[ -f "${_git_alias_env_file}" ]]; then
        _ga_seed_ln="$(grep -m1 '^selected=' "${_git_alias_env_file}" 2>/dev/null || true)"
        [[ -n "${_ga_seed_ln}" ]] && _git_alias_seed_csv="${_ga_seed_ln#selected=}"
      fi
      if [[ "${_git_alias_seed_csv}" == "none" ]]; then
        :
      elif [[ -n "${_git_alias_seed_csv}" ]]; then
        IFS=',' read -ra _ga_seed_ids <<<"${_git_alias_seed_csv}"
        for _ga_id in "${_ga_seed_ids[@]}"; do
          _ga_id="${_ga_id//[[:space:]]/}"
          [[ -n "${_ga_id}" ]] || continue
          for _ga_label in "${_git_alias_labels[@]}"; do
            if [[ "${_ga_label}" == "${_ga_id} → "* ]]; then
              _git_alias_gum_args+=(--selected "${_ga_label}")
            fi
          done
        done
      else
        _git_alias_gum_args=(--selected '*')
      fi
      _git_alias_lines="$(
        # shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
        gum choose --no-limit --ordered --header "Git shortcuts (git <name>)" \
          ${_git_alias_gum_args[@]+"${_git_alias_gum_args[@]}"} \
          ${_git_alias_labels[@]+"${_git_alias_labels[@]}"} || true
      )"
      _git_alias_ids=()
      while IFS= read -r _ga_line || [[ -n "${_ga_line}" ]]; do
        [[ -n "${_ga_line}" ]] || continue
        _git_alias_ids+=("$(botstrap_git_aliases_id_from_label "${_ga_line}")")
      done < <(printf '%s\n' "${_git_alias_lines}")
      if [[ ${#_git_alias_ids[@]} -gt 0 ]]; then
        _git_alias_csv="$(printf '%s,' "${_git_alias_ids[@]}")"
        export BOTSTRAP_GIT_ALIASES="${_git_alias_csv%,}"
      else
        export BOTSTRAP_GIT_ALIASES="none"
      fi
    else
      export BOTSTRAP_GIT_ALIASES="none"
    fi
  else
    export BOTSTRAP_GIT_ALIASES="none"
  fi
fi

_core_yaml="${BOTSTRAP_ROOT}/registry/core.yaml"
_core_tool_names=()
botstrap_read_lines_to_array _core_tool_names < <(yq -r '.tools[].name' "${_core_yaml}")
_selected_flag='*'
_core_env_file="${HOME}/.config/botstrap/core-tools.env"
if [[ -f "${_core_env_file}" ]]; then
  _ln="$(grep -m1 '^core_tools=' "${_core_env_file}" 2>/dev/null || true)"
  if [[ -n "${_ln}" ]]; then
    _v="${_ln#core_tools=}"
    [[ -n "${_v}" ]] && _selected_flag="${_v}"
  fi
fi
_core_lines="$(
  # shellcheck disable=SC2086 # bash32-nounset-empty-array: core list may be empty
  gum choose --no-limit --ordered --header "Core tools (registry/core.yaml)" --selected "${_selected_flag}" ${_core_tool_names[@]+"${_core_tool_names[@]}"} || true
)"
export BOTSTRAP_CORE_TOOLS="${_core_lines//$'\n'/,}"

_opt_sel_file="${HOME}/.config/botstrap/optional-selections.env"
_editor_env_file="${HOME}/.config/botstrap/editor.env"
_theme_env_file="${HOME}/.config/botstrap/theme.env"

_editor_gum_args=()
if [[ -f "${_editor_env_file}" ]]; then
  _edv="$(grep -m1 '^editor=' "${_editor_env_file}" 2>/dev/null | sed 's/^editor=//' || true)"
  [[ -n "${_edv}" ]] && _editor_gum_args=(--selected "${_edv}")
fi
export BOTSTRAP_EDITOR="$(
  # shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
  gum choose --header "Primary editor" ${_editor_gum_args[@]+"${_editor_gum_args[@]}"} \
    cursor vscode neovim zed none
)"

_lang_gum_args=()
if [[ -f "${_opt_sel_file}" ]]; then
  _lcsv="$(grep -m1 '^languages=' "${_opt_sel_file}" 2>/dev/null | sed 's/^languages=//' || true)"
  if [[ -n "${_lcsv}" ]]; then
    IFS=',' read -ra _lp <<<"${_lcsv}"
    for _x in "${_lp[@]}"; do
      _x="${_x//[[:space:]]/}"
      [[ -n "${_x}" ]] && _lang_gum_args+=(--selected "${_x}")
    done
  fi
fi
export BOTSTRAP_LANGUAGES="$(
  # shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
  gum choose --no-limit --header "Programming languages (mise)" ${_lang_gum_args[@]+"${_lang_gum_args[@]}"} \
    node python ruby go rust java elixir php none || true
)"
export BOTSTRAP_LANGUAGES="${BOTSTRAP_LANGUAGES//$'\n'/,}"

_db_gum_args=()
if [[ -f "${_opt_sel_file}" ]]; then
  _dcsv="$(grep -m1 '^databases=' "${_opt_sel_file}" 2>/dev/null | sed 's/^databases=//' || true)"
  if [[ -n "${_dcsv}" ]]; then
    IFS=',' read -ra _dp <<<"${_dcsv}"
    for _x in "${_dp[@]}"; do
      _x="${_x//[[:space:]]/}"
      [[ -n "${_x}" ]] && _db_gum_args+=(--selected "${_x}")
    done
  fi
fi
export BOTSTRAP_DATABASES="$(
  # shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
  gum choose --no-limit --header "Databases (Docker)" ${_db_gum_args[@]+"${_db_gum_args[@]}"} \
    postgresql mysql redis sqlite none || true
)"
export BOTSTRAP_DATABASES="${BOTSTRAP_DATABASES//$'\n'/,}"

_ai_gum_args=()
if [[ -f "${_opt_sel_file}" ]]; then
  _acsv="$(grep -m1 '^ai_tools=' "${_opt_sel_file}" 2>/dev/null | sed 's/^ai_tools=//' || true)"
  if [[ -n "${_acsv}" ]]; then
    IFS=',' read -ra _ap <<<"${_acsv}"
    for _x in "${_ap[@]}"; do
      _x="${_x//[[:space:]]/}"
      [[ -n "${_x}" ]] && _ai_gum_args+=(--selected "${_x}")
    done
  fi
fi
export BOTSTRAP_AI_TOOLS="$(
  # shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
  gum choose --no-limit --header "AI agent CLIs" ${_ai_gum_args[@]+"${_ai_gum_args[@]}"} \
    claude-code openclaw codex gemini ollama none || true
)"
export BOTSTRAP_AI_TOOLS="${BOTSTRAP_AI_TOOLS//$'\n'/,}"

_theme_gum_args=()
if [[ -f "${_theme_env_file}" ]]; then
  _tv="$(grep -m1 '^theme=' "${_theme_env_file}" 2>/dev/null | sed 's/^theme=//' || true)"
  [[ -n "${_tv}" ]] && _theme_gum_args=(--selected "${_tv}")
fi
export BOTSTRAP_THEME="$(
  # shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
  gum choose --header "Theme" ${_theme_gum_args[@]+"${_theme_gum_args[@]}"} \
    catppuccin tokyo-night gruvbox nord rose-pine
)"

_app_gum_args=()
if [[ -f "${_opt_sel_file}" ]]; then
  _ocsv="$(grep -m1 '^optional_apps=' "${_opt_sel_file}" 2>/dev/null | sed 's/^optional_apps=//' || true)"
  if [[ -n "${_ocsv}" ]]; then
    IFS=',' read -ra _op <<<"${_ocsv}"
    for _x in "${_op[@]}"; do
      _x="${_x//[[:space:]]/}"
      [[ -n "${_x}" ]] && _app_gum_args+=(--selected "${_x}")
    done
  fi
fi
export BOTSTRAP_OPTIONAL_APPS="$(
  # shellcheck disable=SC2086 # bash32-nounset-empty-array: optional gum args
  gum choose --no-limit --header "Optional apps" ${_app_gum_args[@]+"${_app_gum_args[@]}"} \
    1password-cli tailscale ngrok postman none || true
)"
export BOTSTRAP_OPTIONAL_APPS="${BOTSTRAP_OPTIONAL_APPS//$'\n'/,}"

if ! gum confirm "Apply these choices and continue?"; then
  botstrap_log_warn "Aborted at confirmation; exiting."
  exit 1
fi

botstrap_log_info "Phase 2 complete."
