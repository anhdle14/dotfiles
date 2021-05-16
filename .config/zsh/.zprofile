# Filename:      zprofile
# Purpose:       system-wide .zprofile file for zsh(1)
# Authors:       grml-team (grml.org), (c) Michael Prokop <mika@grml.org>
# Bug-Reports:   see http://grml.org/bugs/
# License:       This file is licensed under the GPL v2.
################################################################################
# This file is sourced only for login shells (i.e. shells
# invoked with "-" as the first character of argv[0], and
# shells invoked with the -l flag). It's read after zshenv.
#
# Global Order: zshenv, zprofile, zshrc, zlogin
################################################################################

################################################################################

## emsdk
[[ -r $HOME/Developer/github.com/emscripten-core/emsdk/emsdk_env.sh ]] && source $HOME/Developer/github.com/emscripten-core/emsdk/emsdk_env.sh &>/dev/null

if (( EUID != 0 )); then
  case $(uname 2>/dev/null) in
    Darwin)
      # Brew
      # Normally this is all one needed, unfortunately it can not be injected
      # properly. Hence we disable it here and manually update the path
      # eval $($HOME/homebrew/bin/brew shellenv)

      path=(
        $HOME/bin
        $HOME/.local/bin
        $N_PREFIX/bin
        $HOME/.rbenv/bin
        $HOME/.cargo/bin
        $HOME/.emacs.d/bin
        $HOME/go/bin
        $HOME/homebrew/bin
        $HOME/homebrew/sbin
        $HOME/Library/Python/3.9/bin

        /usr/local/bin
        /usr/{bin,sbin}
        /{bin,sbin}
        /Library/Apple/usr/bin
        /usr/libexec

        ${path[@]}
      )
      fpath=(
        $ZDOTDIR/completion
        $ZDOTDIR/.zfunctions
        $HOME/homebrew/share/zsh/site-functions

        ${fpath[@]}
      )
  esac
else
  path=(
    ${ADDONS}
    ${path[@]}
  )
  fpath=(
    ${fpath[@]}
  )
fi

## rbenv
eval "$(rbenv init -)"

## opam
eval $(opam env)

if [ -f $XDG_CONFIG_HOME/gnupg/gpg-agent.conf ]; then
  case $(uname 2>/dev/null) in
    Darwin)
      _pinentry=pinentry-mac
      # brew install gnu-sed
      gsed -i "s|^.*pinentry-program.*$|pinentry-program `which $_pinentry`|" ~/.config/gnupg/gpg-agent.conf
      ;;
    *)
      _pinentry=pinentry
      sed -i "s|^.*pinentry-program.*$|pinentry-program `which $_pinentry`|" ~/.config/gnupg/gpg-agent.conf
      ;;
  esac
fi
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

# Start Emacs if it is not running as Daemon
if [ "$(lsof -c Emacs -c emacs | grep server | tr -s " " | cut -d' ' -f8)" = "" ];
 then
  command emacs --daemon &>/dev/null
fi

################################################################################

## END OF FILE #################################################################
# vim:filetype=zsh foldmethod=marker autoindent expandtab shiftwidth=4
