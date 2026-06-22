#!/usr/bin/env bash
# Remove Botstrap shell integration (Phase 3 markers); optional config purge and checkout removal.
set -euo pipefail

: "${BOTSTRAP_ROOT:?BOTSTRAP_ROOT must be set}"

ROOT="${BOTSTRAP_ROOT}"
# shellcheck source=lib/log.sh
source "${ROOT}/lib/log.sh"

YES=false
PURGE=false
REMOVE_CHECKOUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      YES=true
      ;;
    --purge)
      PURGE=true
      ;;
    --remove-checkout)
      REMOVE_CHECKOUT=true
      ;;
    *)
      botstrap_log_err "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

botstrap_is_botstrap_marker_start() {
  case "$1" in
    '# botstrap PATH' | '# botstrap aliases' | '# botstrap functions')
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Drop Phase 3 blocks: from a # botstrap <known> line until the next line matching ^# botstrap  or EOF.
botstrap_strip_botstrap_blocks_from_rc() {
  local src="$1"
  local out="$2"
  local skip=false
  local line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${skip}" == true ]]; then
      if [[ "${line}" =~ ^#\ botstrap ]]; then
        continue
      fi
      continue
    fi
    if botstrap_is_botstrap_marker_start "${line}"; then
      skip=true
      continue
    fi
    printf '%s\n' "${line}"
  done <"${src}" >"${out}"
}

botstrap_atomic_replace_if_changed() {
  local path="$1"
  local tmp="$2"
  if ! [[ -f "${path}" ]]; then
    rm -f "${tmp}"
    return 0
  fi
  if cmp -s "${path}" "${tmp}"; then
    rm -f "${tmp}"
    return 0
  fi
  mv -f "${tmp}" "${path}"
  botstrap_log_info "Updated ${path}"
}

botstrap_confirm_uninstall() {
  local msg=$'Remove Botstrap shell hooks from your rc files and delete ~/.config/botstrap/env.sh?'
  if [[ "${PURGE}" == true ]]; then
    msg+=$'\nAlso delete the entire ~/.config/botstrap directory (--purge).'
  fi
  if [[ "${REMOVE_CHECKOUT}" == true ]]; then
    msg+=$'\nAlso delete the Botstrap checkout (--remove-checkout):\n'"${ROOT}"
  fi
  if [[ "${YES}" == true ]]; then
    return 0
  fi
  if [[ -t 0 && -t 1 ]] && command -v gum &>/dev/null; then
    gum confirm "${msg}" || {
      botstrap_log_info 'Uninstall cancelled.'
      return 1
    }
    return 0
  fi
  if [[ -t 0 && -t 1 ]]; then
    printf '%s\n' "${msg}"
    read -r -p 'Proceed? [y/N] ' ans || return 1
    case "${ans}" in
      y | Y | yes | YES)
        return 0
        ;;
      *)
        botstrap_log_info 'Uninstall cancelled.'
        return 1
        ;;
    esac
  fi
  botstrap_log_err 'Non-interactive shell: re-run with --yes to confirm uninstall.'
  return 1
}

botstrap_validate_checkout_removal() {
  if [[ -z "${ROOT}" ]]; then
    botstrap_log_err 'Refusing to remove checkout: BOTSTRAP_ROOT is empty.'
    return 1
  fi
  case "${ROOT}" in
    /*) ;;
    *)
      botstrap_log_err "Refusing to remove checkout: path must be absolute (${ROOT})."
      return 1
      ;;
  esac
  if [[ "${ROOT}" == '/' ]]; then
    botstrap_log_err 'Refusing to remove checkout: path is /.'
    return 1
  fi
  if [[ "${ROOT}" == "${HOME}" ]]; then
    botstrap_log_err 'Refusing to remove checkout: path is HOME.'
    return 1
  fi
  if [[ ! -d "${ROOT}/.git" ]]; then
    botstrap_log_err "Refusing to remove checkout: missing ${ROOT}/.git (not a git clone?)."
    return 1
  fi
  return 0
}

if ! botstrap_confirm_uninstall; then
  exit 1
fi

for rc in "${HOME}/.zshrc" "${HOME}/.bashrc"; do
  if [[ -f "${rc}" ]]; then
    tmp="$(mktemp)"
    botstrap_strip_botstrap_blocks_from_rc "${rc}" "${tmp}"
    botstrap_atomic_replace_if_changed "${rc}" "${tmp}"
  fi
done

env_sh="${HOME}/.config/botstrap/env.sh"
if [[ -f "${env_sh}" ]]; then
  rm -f "${env_sh}"
  botstrap_log_info "Removed ${env_sh}"
fi

# shellcheck source=lib/git-aliases.sh
source "${ROOT}/lib/git-aliases.sh"
if [[ "${PURGE}" == true ]]; then
  botstrap_git_aliases_uninstall --purge
else
  botstrap_git_aliases_uninstall
fi

if [[ "${PURGE}" == true ]]; then
  cfg="${HOME}/.config/botstrap"
  if [[ -d "${cfg}" ]]; then
    rm -rf "${cfg}"
    botstrap_log_info "Removed ${cfg}"
  fi
fi

if [[ "${REMOVE_CHECKOUT}" == true ]]; then
  if ! botstrap_validate_checkout_removal; then
    exit 1
  fi
  rm -rf "${ROOT}"
  botstrap_log_info "Removed checkout ${ROOT}"
fi

botstrap_log_info 'Botstrap uninstall finished.'
