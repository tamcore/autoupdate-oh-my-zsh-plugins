# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# self-update

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------

function _autoupdate_setup_colors() {
  local ncolors=0
  if command -v tput >/dev/null 2>&1; then
    ncolors=$(tput colors 2>/dev/null)
  fi

  if [[ $- == *i* ]] && (( ${ncolors:-0} >= 8 )); then
    RED="$(tput setaf 1)"
    BLUE="$(tput setaf 4)"
    GREEN="$(tput setaf 2)"
    NORMAL="$(tput sgr0)"
  else
    RED=""
    BLUE=""
    GREEN=""
    NORMAL=""
  fi
}
_autoupdate_setup_colors
unset -f _autoupdate_setup_colors

# ---------------------------------------------------------------------------
# Core helpers
# ---------------------------------------------------------------------------

zmodload zsh/datetime

function _current_epoch() {
  echo $(( EPOCHSECONDS / 60 / 60 / 24 ))
}

function _update_zsh_custom_update() {
  echo "LAST_EPOCH=$(_current_epoch)" >| "${ZSH_CACHE_DIR}/.zsh-custom-update"
}

function _get_epoch_target() {
  local epoch_target

  zstyle -g epoch_target ':omz:update' frequency \
    || epoch_target="$UPDATE_ZSH_DAYS"

  if [[ -z "$epoch_target" ]]; then
    epoch_target=13
  fi

  echo "$epoch_target"
}

function _dispatch_update_mode() {
  local mode

  zstyle -g mode ':omz:update' mode

  if [[ -z "$mode" ]]; then
    if [[ "$DISABLE_AUTO_UPDATE" == "true" ]]; then
      mode="disabled"
    elif [[ "$DISABLE_UPDATE_PROMPT" == "true" ]]; then
      mode="auto"
    else
      mode="prompt"
    fi
  fi

  echo "$mode"
}

# ---------------------------------------------------------------------------
# Plugin upgrade
# ---------------------------------------------------------------------------

function _upgrade_custom_plugin() {
  local d="$1"
  local p pn pt last_head curr_head

  p=$(dirname "$d")
  pn=$(basename "$p")
  pt=$(basename "$(dirname "$p")")
  pt="${pt%?}"

  if [[ -n "$ZSH_CUSTOM_AUTOUPDATE_IGNORE" ]]; then
    local ignored
    while IFS= read -r ignored; do
      [[ -z "$ignored" ]] && continue
      if [[ "$pn" == "$ignored" ]]; then
        printf "${BLUE}%s${NORMAL}\n" "Skipping $pn $pt (in ignore list)"
        return 0
      fi
    done < <(echo "$ZSH_CUSTOM_AUTOUPDATE_IGNORE" | tr ',;: ' '\n' | grep -v '^$')
  fi

  last_head=$(git -C "$p" rev-parse HEAD)

  if git -C "$p" pull --quiet --rebase --stat --autostash; then
    curr_head=$(git -C "$p" rev-parse HEAD)
    if [[ "$last_head" != "$curr_head" ]]; then
      printf "${GREEN}%s${NORMAL}\n" "Hooray! the $pn $pt has been updated."
    else
      printf "${BLUE}%s${NORMAL}\n" "The $pn $pt was already at the latest version."
    fi
  else
    printf "${RED}%s${NORMAL}\n" "There was an error updating the $pn $pt. Try again later?"
  fi
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

function upgrade_oh_my_zsh_custom() {
  if [[ -z "$ZSH_CUSTOM_AUTOUPDATE_QUIET" ]]; then
    printf "${BLUE}%s${NORMAL}\n" "Upgrading Custom Plugins"
  fi

  local num_workers i=0
  num_workers=$(printf "%.0f" "$ZSH_CUSTOM_AUTOUPDATE_NUM_WORKERS")

  local use_parallel=false
  if (( num_workers > 1 && num_workers <= 16 )); then
    use_parallel=true
  fi

  set +m
  find -L "${ZSH_CUSTOM}" -maxdepth 3 -name .git | while IFS= read -r d; do
    if [[ "$use_parallel" == true ]]; then
      (( i = (i + 1) % num_workers )) || wait
      ( _upgrade_custom_plugin "$d" ) &
    else
      _upgrade_custom_plugin "$d"
    fi
  done
  wait
  set -m
}

alias upgrade_oh_my_zsh_all='zsh "$ZSH/tools/upgrade.sh"; upgrade_oh_my_zsh_custom'

# ---------------------------------------------------------------------------
# Legacy cache migration
# ---------------------------------------------------------------------------

if [[ -f ~/.zsh-custom-update ]]; then
  mv ~/.zsh-custom-update "${ZSH_CACHE_DIR}/.zsh-custom-update"
fi

# ---------------------------------------------------------------------------
# Auto-update check
# ---------------------------------------------------------------------------

function _autoupdate_init() {
  local epoch_target update_mode

  epoch_target="$(_get_epoch_target)"
  update_mode="$(_dispatch_update_mode)"

  if [[ "$update_mode" == "disabled" ]]; then
    return
  fi

  if [[ ! -f "${ZSH_CACHE_DIR}/.zsh-custom-update" ]]; then
    _update_zsh_custom_update
    return
  fi

  local LAST_EPOCH=0
  . "${ZSH_CACHE_DIR}/.zsh-custom-update"

  local epoch_diff
  epoch_diff=$(( $(_current_epoch) - LAST_EPOCH ))

  if (( epoch_diff > epoch_target )); then
    if [[ "$update_mode" == "auto" ]]; then
      ( upgrade_oh_my_zsh_custom )
    elif [[ "$update_mode" == "reminder" ]]; then
      echo "[oh-my-zsh] It's time to update! You can do that by running \`upgrade_oh_my_zsh_custom\`"
    else
      echo "[oh-my-zsh] Would you like to check for custom plugin updates? [Y/n]: \c"
      local line
      read line
      if [[ "$line" == Y* ]] || [[ "$line" == y* ]] || [[ -z "$line" ]]; then
        ( upgrade_oh_my_zsh_custom )
      fi
    fi
    _update_zsh_custom_update
  fi
}

_autoupdate_init

unset -f _update_zsh_custom_update _current_epoch \
  _get_epoch_target _dispatch_update_mode _autoupdate_init
