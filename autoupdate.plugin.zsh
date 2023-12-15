# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# self-update

if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors)
fi

if [[ $- == *i* ]] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  RED="$(tput setaf 1)"
  BLUE="$(tput setaf 4)"
  NORMAL="$(tput sgr0)"
else
  BLUE=""
  BOLD=""
  NORMAL=""
fi

zmodload zsh/datetime

function _current_epoch() {
  echo $(( $EPOCHSECONDS / 60 / 60 / 24 ))
}

function _update_zsh_custom_update() {
  echo "LAST_EPOCH=$(_current_epoch)" >| "${ZSH_CACHE_DIR}/.zsh-custom-update"
}

function _get_epoch_target() {
  local epoch_target

  zstyle -g epoch_target ':omz:update' frequency \
    || epoch_target="$UPDATE_ZSH_DAYS"
  if [[ -z "$epoch_target" ]]; then
    # Default to old behavior
    epoch_target=13
  fi

  echo "$epoch_target"
}

epoch_target="$(_get_epoch_target)"

function _upgrade_custom_plugin() {
  # path of plugin/theme
  p=$(dirname "$d")
  # it's name
  pn=$(basename "$p")
  # it's type (plugin/theme)
  pt=$(dirname "$p")
  pt=$(basename ${pt:0:((${#pt} - 1))})

  last_head=$( git -C "${p}" rev-parse HEAD )
  if git -C "${p}" pull --quiet --rebase --stat --autostash
  then
    curr_head=$( git -C "${p}" rev-parse HEAD )
    if [ "${last_head}" != "${curr_head}" ]
    then
      printf "${BLUE}%s${NORMAL}\n" "Hooray! the $pn $pt has been updated."
    else
      printf "${BLUE}%s${NORMAL}\n" "The $pn $pt was already at the latest version."
    fi
  else
    printf "${RED}%s${NORMAL}\n" "There was an error updating the $pn $pt. Try again later?"
  fi
}

function upgrade_oh_my_zsh_custom() {
  if [[ -z "$ZSH_CUSTOM_AUTOUPDATE_QUIET" ]]; then
    printf "${BLUE}%s${NORMAL}\n" "Upgrading Custom Plugins"
  fi

  num_workers=$( printf "%.0f" "$ZSH_CUSTOM_AUTOUPDATE_NUM_WORKERS" )
  set +m
  find -L "${ZSH_CUSTOM}" -type d -name .git | while read d
  do
    if ! test $num_workers -gt 1 2> /dev/null || \
    test $num_workers -gt 16 2> /dev/null; then
      _upgrade_custom_plugin "${d}"
    else
      ((i=(i+1)%$num_workers)) || wait
      (_upgrade_custom_plugin "${d}") &
    fi
  done
  wait
  set -m
}

alias upgrade_oh_my_zsh_all='omz update && upgrade_oh_my_zsh_custom'


if [ -f ~/.zsh-custom-update ]
then
  mv ~/.zsh-custom-update "${ZSH_CACHE_DIR}/.zsh-custom-update"
fi

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

update_mode="$(_dispatch_update_mode)"

if [[ "$update_mode" == "disabled" ]]
then
  # No updates
elif [ -f "${ZSH_CACHE_DIR}/.zsh-custom-update" ]
then
  . "${ZSH_CACHE_DIR}/.zsh-custom-update"

  if [[ -z "$LAST_EPOCH" ]]
  then
    LAST_EPOCH=0
  fi

  epoch_diff=$(($(_current_epoch) - $LAST_EPOCH))
  if [ $epoch_diff -gt $epoch_target ]
  then
    if [[ "$update_mode" == "auto" ]]
    then
      (upgrade_oh_my_zsh_custom)
    elif [[ "$update_mode" == "reminder" ]]
    then
      echo "[oh-my-zsh] It's time to update! You can do that by running \`upgrade_oh_my_zsh_custom\`"
    else
      echo "[oh-my-zsh] Would you like to check for custom plugin updates? [Y/n]: \c"
      read line
      if [[ "$line" == Y* ]] || [[ "$line" == y* ]] || [ -z "$line" ]
      then
        (upgrade_oh_my_zsh_custom)
      fi
    fi
    _update_zsh_custom_update
  fi
else
  _update_zsh_custom_update
fi

unset -f _update_zsh_custom_update _current_epoch \
  _get_epoch_target _dispatch_update_mode
