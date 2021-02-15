# Maddy's ZSH Configuration

This is my configuration for [zsh](http://www.zsh.org/).

Highlights:

- Plugins managed by [zinit](https://github.com/zdharma/zinit)
- Lots of neat aliases and autoloaded functions
- Some handy zle widgets

Unfortunately it's rather messy!

## Cloning

This repository contains zinit as a git submodule, so be sure to initialize it:

```sh
$ # initialize submodules at clone:
$ git clone --recurse-submodules https://github.com/b0o/zsh-conf
$ # Or initialize submodules after clone:
$ git submodule update --init --recursive
```

## Installing

I like to keep this repository at `~/.config/zsh`. If you'd like to do the
same, make sure you set up the `ZDOTDIR` environment variable. I do this in the
`/etc/zsh/zshenv` (or `/etc/zshenv`, depending on your distribution) file like
so:

```zsh
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
```

## License

&copy; 2016-2021 Maddison Hellstrom

Released under the GNU General Public License, version 3 or later.
