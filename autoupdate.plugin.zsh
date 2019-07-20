# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# self-update

if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors)
fi

if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
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
  echo "LAST_EPOCH=$(_current_epoch)" >! "${ZSH_CACHE_DIR}/.zsh-custom-update"
}

epoch_target=$UPDATE_ZSH_DAYS
if [[ -z "$epoch_target" ]]; then
  # Default to old behavior
  epoch_target=13
fi

function _upgrade_custom() {
  printf "${BLUE}%s${NORMAL}\n" "Upgrading custom plugins"

  find "${ZSH_CUSTOM}" -type d -name .git | while read d
  do
    p=$(dirname "$d")
    cd "${p}"

    if git pull --rebase --stat origin master
    then
      printf "${BLUE}%s${NORMAL}\n" "Hooray! $d has been updated and/or is at the current version."
    else
      printf "${RED}%s${NORMAL}\n" 'There was an error updating. Try again later?'
    fi
  done
}

if [ -f ~/.zsh-custom-update ]
then
  mv ~/.zsh-custom-update "${ZSH_CACHE_DIR}/.zsh-custom-update"
fi

if [ -f "${ZSH_CACHE_DIR}/.zsh-custom-update" ]
then
  . "${ZSH_CACHE_DIR}/.zsh-custom-update"

  if [[ -z "$LAST_EPOCH" ]]
  then
    LAST_EPOCH=0
  fi

  epoch_diff=$(($(_current_epoch) - $LAST_EPOCH))
  if [ $epoch_diff -gt $epoch_target ]
  then
    if [ "$DISABLE_UPDATE_PROMPT" = "true" ]
    then
      (_upgrade_custom)
    else
      echo "[Oh My Zsh] Would you like to check for custom plugin updates? [Y/n]: \c"
      read line
      if [[ "$line" == Y* ]] || [[ "$line" == y* ]] || [ -z "$line" ]
      then
        (_upgrade_custom)
      fi
    fi
    _update_zsh_custom_update
  fi
else
  _update_zsh_custom_update
fi

unset -f _update_zsh_custom_update _upgrade_custom _current_epoch
