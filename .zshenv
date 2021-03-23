# Filename:      zshenv
# Purpose:       system-wide .zshenv file for zsh(1)
# Authors:       grml-team (grml.org), (c) Michael Prokop <mika@grml.org>
# Bug-Reports:   see http://grml.org/bugs/
# License:       This file is licensed under the GPL v2.
################################################################################
# This file is sourced on all invocations of the shell.
# It is the 1st file zsh reads; it's read for every shell,
# even if started with -f (setopt NO_RCS), all other
# initialization files are skipped.
#
# This file should contain commands to set the command
# search path, plus other important environment variables.
# This file should not contain commands that produce
# output or assume the shell is attached to a tty.
#
# Notice: .zshenv is the same, execpt that it's not read
# if zsh is started with -f
#
# Global Order: zshenv, zprofile, zshrc, zlogin
################################################################################


# language settings (read in /etc/environment before /etc/default/locale as
# the latter one is the default on Debian nowadays)
# no xsource() here because it's only created in zshrc! (which is good)
[[ -r /etc/environment ]] && source /etc/environment

if [ -n "${LANG}" ] ; then
  export LANG=en_US.UTF-8
fi
if [ -n "${LC_CTYPE}" ] ; then
  export LC_CTYPE=en_US.UTF-8
fi

# set environment variables (important for autologin on tty)
if [ -n "${HOSTNAME}" ] ; then
  export HOSTNAME="${HOSTNAME}"
else
  export HOSTNAME="$(uname -n)"
fi

# make sure /usr/bin/id is available
if [[ -x /usr/bin/id ]] ; then
  [[ -z "$USER" ]]          && export USER=$(/usr/bin/id -un)
  [[ $LOGNAME == LOGIN ]] && LOGNAME=$(/usr/bin/id -un)
fi

# Golang
export GOPATH=$HOME/go

# Airflow
export AIRFLOW_HOME=$HOME/airflow

# Exports
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/.ripgreprc
export SCREENRC=$XDG_CONFIG_HOME/.screenrc
export BAT_CONFIG_PATH=$XDG_CONFIG_HOME/bat/bat.conf
export DOTDIR=$XDG_CONFIG_HOME/dotfiles
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

export ALTERNATE_EDITOR="vi"
export EDITOR="emacsclient -t"                  # $EDITOR opens in terminal
export VISUAL="emacsclient -c -a"               # $VISUAL opens in GUI mode

export N_PREFIX="$HOME/n";

case $(uname 2>/dev/null) in
  Darwin)
    # Homebrew
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
    
    # Whalebrew
    export WHALEBREW_INSTALL_PATH="$HOME/bin"

    ## Homebrew Bundle
    export HOMEBREW_BUNDLE_FILE="$HOME/backups/homebrew/Brewfile"

    ## Java
    export JAVA_HOME=`/usr/libexec/java_home`

    ## Android Studio
    export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
    export ANDROID_HOME=$ANDROID_SDK_ROOT
    
    ## Azure Functions
    export FUNCTIONS_CORE_TOOLS_TELEMETRY_OUTPUT=1

    ## Iterm2
    export ITERM2_SQUELCH_MARK=1
    ;;
  *)
    # TODO: Fix JAVA_HOME for other distributions.
    export JAVA_HOME=""
    ;;
esac

# Kill the lag with <ESC> key
export KEYTIMEOUT=1

# gpg-agent has OpenSSH agent emulation.
export GNUPGHOME=$XDG_CONFIG_HOME/gnupg
export GPG_TTY="$(tty)"

## END OF FILE #################################################################
# vim:filetype=zsh foldmethod=marker autoindent expandtab shiftwidth=2
