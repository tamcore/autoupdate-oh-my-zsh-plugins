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

```bash
plugins=(autoupdate)

# Multiple plugins should be separated by space character
# plugins=(somePlugin autoupdate)
```

By default this will auto update both plugins and themes, found in the $ZSH_CUSTOM folder, every 13 days (which is the OhMyZsh default).

If you want to check for updates more or less often, you can export the `UPDATE_ZSH_DAYS` variable in your `~/.zshrc` file:
```bash
# to check for updates once a month
export UPDATE_ZSH_DAYS=30
# or to check for updates daily
export UPDATE_ZSH_DAYS=1
```

Another possibility is to use the provided upgrade function, which one may call
at any time using `upgrade_oh_my_zsh_custom`. There shouldn't be any difference
with the automatic operation. Also, a convenient alias that calls the OhMyZsh
update function `omz update` and then `upgrade_oh_my_zsh_custom`, called
`upgrade_oh_my_zsh_all`, is available as well. However, running `omz update` directly **will not** trigger the this plugin.

### Quiet mode

To turn off the "Upgrading custom plugins" message (for example, if you're using [Powerlevel10k's instant prompt](https://github.com/romkatv/powerlevel10k#instant-prompt)), add this to your `~/.zshrc` file:
```shell
# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13
ZSH_CUSTOM_AUTOUPDATE_QUIET=true
```

### Parallel downloads

To speed up updates by setting maximum number of parallel downloads, add this to your `~/.zshrc` file:
```shell
# Values accepted (min: 1, max: 16)
# Parallel downloads will not be enabled if value is out-of-range
ZSH_CUSTOM_AUTOUPDATE_NUM_WORKERS=8
```
