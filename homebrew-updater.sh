#!/bin/bash

# File names and paths
last_updated_file=".brew-last-update"
last_updated_file_path="$HOME/${last_updated_file}"
debug_file_path="${UPDATE_HOMEBREW_PATH:-$(pwd)}/debug.log"
old_last_updated_file_path_content=$(head -n 1 "${last_updated_file_path}")

# Debug logger syntax
info_tag="INFO"
warning_tag="WARN"
sep=":"
lineDash="-----------------------"

# Homebrew auto-update steps
function homebrew_updater() {
  command="brew update && brew upgrade && brew upgrade --cask --greedy"
  printf "%s\nRunning upgrade command: %s\n%s\n" "${lineDash}" "${command}" "${lineDash}"
  eval "${command}"
}

function debug_logger_reset() {
  printf "%s \n%s \n" "Debug Logger" "${lineDash}" >"${debug_file_path}"
}

function debug_logger() {
  tag_type=${1}
  echo "${tag_type} ${sep} ${2}" >>"${debug_file_path}"
}

function current_epoch() {
  zmodload zsh/datetime
  echo $((EPOCHSECONDS / 60 / 60 / 24))
}

function update_last_updated_file() {
  last_epoch=$(current_epoch)
  debug_logger "${info_tag}" "Updating '${last_updated_file_path}' to: '${last_epoch}'."
  echo "LAST_EPOCH=${last_epoch}" >"${last_updated_file_path}"
}

function reset_last_updated_file() {
  debug_logger "${info_tag}" "Homebrew upgrade returned non-zero exit code, resetting '${last_updated_file_path}' to: '$old_last_updated_file_path_content'."
  echo "$old_last_updated_file_path_content" >"${last_updated_file_path}"
}

function update_homebrew() {
  update_last_updated_file
  if ! homebrew_updater; then
    reset_last_updated_file
  fi
}

function update_homebrew_prompt() {
  # Input sink to swallow all characters typed before the prompt
  #  and add a newline if there wasn't one after characters typed.
  # shellcheck disable=SC2162
  while read -t -k 1 option; do true; done
  [[ "$option" != $'\n' ]] || [[ "$option" != "" ]] && echo

  echo -n "[Homebrew] Would you like to upgrade all packages? [Y/n] "
  read -r -k 1 option
  [[ "$option" != $'\n' ]] && echo
  case "$option" in
  [yY$'\n']) debug_logger "${info_tag}" "Input - Update Homebrew." && update_homebrew ;;
  [nN]) debug_logger "${info_tag}" "Input - Do not update Homebrew." && update_last_updated_file ;;
  esac
  debug_logger "${info_tag}" "Script exiting successfully (0)"
}

function main() {
  debug_logger_reset

  emulate -L zsh

  local epoch_target
  local option
  local LAST_EPOCH

  # Create or update last_updated_file file if missing or malformed.
  # shellcheck disable=SC1090
  if ! source "${last_updated_file_path}" 2>/dev/null || [[ -z "$LAST_EPOCH" ]]; then
    debug_logger "${warning_tag}" "Cannot find '${last_updated_file_path}' file, or it's malformed."
    update_last_updated_file
    debug_logger "${warning_tag}" "Script exiting unsuccessfully (1)"
    return
  else
    debug_logger "${info_tag}" "Found '${last_updated_file_path}' file."
  fi

  # Number of days before trying to update again.
  epoch_target=${UPDATE_HOMEBREW_DAYS:-7}
  debug_logger "${info_tag}" "UPDATE_HOMEBREW_DAYS set to ${UPDATE_HOMEBREW_DAYS} days."
  debug_logger "${info_tag}" "Current EPOCH - $(current_epoch) | Last EPOCH - ${LAST_EPOCH}"

  # Test if enough time has passed until the next update.
  if ((($(current_epoch) - LAST_EPOCH) < epoch_target)); then
    debug_logger "${warning_tag}" "Not enough time has passed."
    debug_logger "${warning_tag}" "Script exiting unsuccessfully (2)"
    return
  else
    debug_logger "${info_tag}" "Enough time has passed, loading Homebrew auto-update prompt."
  fi

  # Load homebrew update prompt.
  update_homebrew_prompt
}

main
