autoupdate-zsh-plugin
====================

[oh-my-zsh plugin](https://github.com/robbyrussell/oh-my-zsh) for auto updating of git-repositories in $ZSH_CUSTOM folder

## Install

Create a new directory in `$ZSH_CUSTOM/plugins` called `autoupdate` and clone this repo into that directory. Note: it must be named `autoupdate` or oh-my-zsh won't recognize that it is a valid plugin directory.
```
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $ZSH_CUSTOM/plugins/autoupdate
```

## Usage

Add `autoupdate` to the `plugins=()` list in your `~/.zshrc` file and you're done.
The updates will be executed automatically as soon as the oh-my-zsh updater is started.
Note that this will autoupdate both plugins and also themes found in the $ZSH_CUSTOM folder.

If you want to check for updates more often, you can adjust this line in the `~/.zshrc` file.
Default command:
```shell
# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13
```
Changed command: (checks daily for updates)
```shell
# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=1
```

Another possibility is to use the provided upgrade function, which one may call
at any time using `upgrade_oh_my_zsh_custom`. There shouldn't be any difference
with the automatic operation. Also, a convenient alias that calls the OhMyZsh
update function `upgrade_oh_my_zsh` and then `upgrade_oh_my_zsh_custom`, called
`upgrade_ohl_my_zsh`, is available as well.

### Quiet mode

To turn off the "Upgrading custom plugins" message (for example, if you're using [Powerlevel10k's instant prompt](https://github.com/romkatv/powerlevel10k#instant-prompt)), add this to your `~/.zshrc` file:
```shell
# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13
ZSH_CUSTOM_AUTOUPDATE_QUIET=true
```