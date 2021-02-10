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

case $(uname 2>/dev/null) in
  Darwin)
    # Homebrew
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"

    ## Homebrew Bundle
    export HOMEBREW_BUNDLE_FILE="$HOME/backups/homebrew/Brewfile"

    ## Java
    export JAVA_HOME=`/usr/libexec/java_home`

    ## Android Studio
    export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
    export ANDROID_HOME=$ANDROID_SDK_ROOT

    ## MacPrefs
    export MACPREFS_BACKUP_DIR="$HOME/backups/macprefs"
    
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
################################################################################

## END OF FILE #################################################################
# vim:filetype=zsh foldmethod=marker autoindent expandtab shiftwidth=4
