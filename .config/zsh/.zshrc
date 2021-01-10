# load .zshrc.pre to give the user the chance to overwrite the defaults
[[ -r ${ZDOTDIR:-${HOME}}/.zshrc.pre ]] && source ${ZDOTDIR:-${HOME}}/.zshrc.pre

OSTYPE=$(uname -s)

function islinux () {
    [[ $OSTYPE == "Linux" ]]
}

function isdarwin () {
    [[ $OSTYPE == "Darwin" ]]
}

function isfreebsd () {
    [[ $OSTYPE == "FreeBSD" ]]
}

function isopenbsd () {
    [[ $OSTYPE == "OpenBSD" ]]
}

function issolaris () {
    [[ $OSTYPE == "SunOS" ]]
}

# autoload wrapper - use this one instead of autoload directly
# We need to define this function as early as this, because autoloading
# 'is-at-least()' needs it.
function zrcautoload () {
    emulate -L zsh
    setopt extended_glob
    local fdir ffile
    local -i ffound

    ffile=$1
    (( ffound = 0 ))
    for fdir in ${fpath} ; do
        [[ -e ${fdir}/${ffile} ]] && (( ffound = 1 ))
    done

    (( ffound == 0 )) && return 1
    if [[ $ZSH_VERSION == 3.1.<6-> || $ZSH_VERSION == <4->* ]] ; then
        autoload -U ${ffile} || return 1
    else
        autoload ${ffile} || return 1
    fi
    return 0
}

# set some important options (as early as possible)

# append history list to the history file; this is the default but we make sure
# because it's required for share_history.
setopt append_history

# save each command's beginning timestamp and the duration to the history file
setopt extended_history

# remove command lines from the history list when the first character on the
# line is a space
setopt histignorespace

# if a command is issued that can't be executed as a normal command, and the
# command is the name of a directory, perform the cd command to that directory.
setopt auto_cd

# in order to use #, ~ and ^ for filename generation rg word
# *~(*.gz|*.bz|*.bz2|*.zip|*.Z) -> searches for word not in compressed files
# don't forget to quote '^', '~' and '#'!
setopt extended_glob

# display PID when suspending processes as well
setopt longlistjobs

# report the status of backgrounds jobs immediately
setopt notify

# whenever a command completion is attempted, make sure the entire command path
# is hashed first.
setopt hash_list_all

# not just at the end
setopt completeinword

# Don't send SIGHUP to background processes when the shell exits.
setopt nohup

# make cd push the old directory onto the directory stack.
setopt auto_pushd

# avoid "beep"ing
setopt nobeep

# don't push the same dir twice.
setopt pushd_ignore_dups

# * shouldn't match dotfiles. ever.
setopt noglobdots

# use zsh style word splitting
setopt noshwordsplit

# don't error out when unset parameters are used
setopt unset

typeset -ga ls_options
typeset -ga rg_options

# Colors on GNU ls(1)
if ls --color=auto / >/dev/null 2>&1; then
  ls_options+=( --color=auto )
# Colors on FreeBSD and OSX ls(1)
elif ls -G / >/dev/null 2>&1; then
  ls_options+=( -G )
fi

# Natural sorting order on GNU ls(1)
# OSX and IllumOS have a -v option that is not natural sorting
if ls --version |& rg -q 'GNU' >/dev/null 2>&1 && ls -v / >/dev/null 2>&1; then
  ls_options+=( -v )
fi

# Color on GNU and FreeBSD rg(1)
if rg --color=auto -q "a" <<< "a" >/dev/null 2>&1; then
  rg_options+=( --color=auto )
fi

# utility functions
# this function checks if a command exists and returns either true
# or false. This avoids using 'which' and 'whence', which will
# avoid problems with aliases for which on certain weird systems. :-)
# Usage: check_com [-c|-g] word
#   -c  only checks for external commands
#   -g  does the usual tests and also checks for global aliases
function check_com () {
  emulate -L zsh
  local -i comonly gatoo
  comonly=0
  gatoo=0

  if [[ $1 == '-c' ]] ; then
    comonly=1
    shift 1
  elif [[ $1 == '-g' ]] ; then
    gatoo=1
    shift 1
  fi

  if (( ${#argv} != 1 )) ; then
    printf 'usage: check_com [-c|-g] <command>\n' >&2
    return 1
  fi

  if (( comonly > 0 )) ; then
    (( ${+commands[$1]}  )) && return 0
    return 1
  fi

  if   (( ${+commands[$1]}    )) \
    || (( ${+functions[$1]}   )) \
    || (( ${+aliases[$1]}     )) \
    || (( ${+reswords[(r)$1]} )) ; then
    return 0
  fi

  if (( gatoo > 0 )) && (( ${+galiases[$1]} )) ; then
    return 0
  fi

  return 1
}

# creates an alias and precedes the command with
# sudo if $EUID is not zero.
function salias () {
  emulate -L zsh
  local only=0 ; local multi=0
  local key val
  while getopts ":hao" opt; do
    case $opt in
      o) only=1 ;;
      a) multi=1 ;;
      h)
        printf 'usage: salias [-hoa] <alias-expression>\n'
        printf '  -h      shows this help text.\n'
        printf '  -a      replace '\'' ; '\'' sequences with '\'' ; sudo '\''.\n'
        printf '          be careful using this option.\n'
        printf '  -o      only sets an alias if a preceding sudo would be needed.\n'
        return 0
        ;;
      *) salias -h >&2; return 1 ;;
    esac
  done
  shift "$((OPTIND-1))"

  if (( ${#argv} > 1 )) ; then
    printf 'Too many arguments %s\n' "${#argv}"
    return 1
  fi

  key="${1%%\=*}" ;  val="${1#*\=}"
  if (( EUID == 0 )) && (( only == 0 )); then
    alias -- "${key}=${val}"
  elif (( EUID > 0 )) ; then
    (( multi > 0 )) && val="${val// ; / ; sudo }"
    alias -- "${key}=sudo ${val}"
  fi

  return 0
}

# Check if we can read given files and source those we can.
function xsource () {
  if (( ${#argv} < 1 )) ; then
    printf 'usage: xsource FILE(s)...\n' >&2
    return 1
  fi

  while (( ${#argv} > 0 )) ; do
    [[ -r "$1" ]] && source "$1"
    shift
  done
  return 0
}

# this allows us to stay in sync with grml's zshrc and put own
# modifications in ~/.zshrc.local
function zrclocal () {
  xsource "/etc/zsh/zshrc.local"
  xsource "${ZDOTDIR:-${HOME}}/.zshrc.local"
  return 0
}

#v#
export PAGER=${PAGER:-less}

# color setup for ls:
check_com -c dircolors && eval $(dircolors -b)
# color setup for ls on OS X / FreeBSD:
isdarwin && export CLICOLOR=1
isfreebsd && export CLICOLOR=1

# watch for everyone but me and root
watch=(notme root)

# automatically remove duplicates from these arrays
typeset -U path PATH cdpath CDPATH fpath FPATH manpath MANPATH

# completion system
COMPDUMPFILE=${COMPDUMPFILE:-${ZDOTDIR:-${HOME}}/.zcompdump}
if zrcautoload compinit ; then
  typeset -a tmp
  zstyle -a ':grml:completion:compinit' arguments tmp
  compinit -d ${COMPDUMPFILE} "${tmp[@]}"
  unset tmp
else
  function compdef { }
fi

# Use vi-like key bindings by default:
bindkey -v

## beginning-of-line OR beginning-of-buffer OR beginning of history
## by: Bart Schaefer <schaefer@brasslantern.com>, Bernhard Tittelbach
function beginning-or-end-of-somewhere () {
  local hno=$HISTNO
  if [[ ( "${LBUFFER[-1]}" == $'\n' && "${WIDGET}" == beginning-of* ) || \
    ( "${RBUFFER[1]}" == $'\n' && "${WIDGET}" == end-of* ) ]]; then
      zle .${WIDGET:s/somewhere/buffer-or-history/} "$@"
  else
    zle .${WIDGET:s/somewhere/line-hist/} "$@"
    if (( HISTNO != hno )); then
      zle .${WIDGET:s/somewhere/buffer-or-history/} "$@"
    fi
  fi
}
zle -N beginning-of-somewhere beginning-or-end-of-somewhere
zle -N end-of-somewhere beginning-or-end-of-somewhere

# add a command line to the shells history without executing it
function commit-to-history () {
  print -rs ${(z)BUFFER}
  zle send-break
}
zle -N commit-to-history

# only slash should be considered as a word separator:
function slash-backward-kill-word () {
  local WORDCHARS="${WORDCHARS:s@/@}"
  # zle backward-word
  zle backward-kill-word
}
zle -N slash-backward-kill-word

# a generic accept-line wrapper

# This widget can prevent unwanted autocorrections from command-name
# to _command-name, rehash automatically on enter and call any number
# of builtin and user-defined widgets in different contexts.
#
# For a broader description, see:
# <http://bewatermyfriend.org/posts/2007/12-26.11-50-38-tooltime.html>
#
# The code is imported from the file 'zsh/functions/accept-line' from
# <http://ft.bewatermyfriend.org/comp/zsh/zsh-dotfiles.tar.bz2>, which
# distributed under the same terms as zsh itself.

# A newly added command will may not be found or will cause false
# correction attempts, if you got auto-correction set. By setting the
# following style, we force accept-line() to rehash, if it cannot
# find the first word on the command line in the $command[] hash.
zstyle ':acceptline:*' rehash true

function Accept-Line () {
  setopt localoptions noksharrays
  local -a subs
  local -xi aldone
  local sub
  local alcontext=${1:-$alcontext}

  zstyle -a ":acceptline:${alcontext}" actions subs

  (( ${#subs} < 1 )) && return 0

  (( aldone = 0 ))
  for sub in ${subs} ; do
    [[ ${sub} == 'accept-line' ]] && sub='.accept-line'
    zle ${sub}

    (( aldone > 0 )) && break
  done
}

function Accept-Line-getdefault () {
  emulate -L zsh
  local default_action

  zstyle -s ":acceptline:${alcontext}" default_action default_action
  case ${default_action} in
    ((accept-line|))
      printf ".accept-line"
      ;;
    (*)
      printf ${default_action}
      ;;
  esac
}

function Accept-Line-HandleContext () {
  zle Accept-Line

  default_action=$(Accept-Line-getdefault)
  zstyle -T ":acceptline:${alcontext}" call_default \
    && zle ${default_action}
}

function accept-line () {
  setopt localoptions noksharrays
  local -a cmdline
  local -x alcontext
  local buf com fname format msg default_action

  alcontext='default'
  buf="${BUFFER}"
  cmdline=(${(z)BUFFER})
  com="${cmdline[1]}"
  fname="_${com}"

  Accept-Line 'preprocess'

  zstyle -t ":acceptline:${alcontext}" rehash \
    && [[ -z ${commands[$com]} ]]           \
    && rehash

  if   [[ -n ${com}               ]] \
    && [[ -n ${reswords[(r)$com]} ]] \
    || [[ -n ${aliases[$com]}     ]] \
    || [[ -n ${functions[$com]}   ]] \
    || [[ -n ${builtins[$com]}    ]] \
    || [[ -n ${commands[$com]}    ]] ; then

     # there is something sensible to execute, just do it.
    alcontext='normal'
    Accept-Line-HandleContext

    return
  fi

  if    [[ -o correct              ]] \
    || [[ -o correctall           ]] \
    && [[ -n ${functions[$fname]} ]] ; then

    # nothing there to execute but there is a function called
    # _command_name; a completion widget. Makes no sense to
    # call it on the commandline, but the correct{,all} options
    # will ask for it nevertheless, so warn the user.
    if [[ ${LASTWIDGET} == 'accept-line' ]] ; then
      # Okay, we warned the user before, he called us again,
      # so have it his way.
      alcontext='force'
      Accept-Line-HandleContext

      return
    fi

    if zstyle -t ":acceptline:${alcontext}" nocompwarn ; then
      alcontext='normal'
      Accept-Line-HandleContext
    else
      # prepare warning message for the user, configurable via zstyle.
      zstyle -s ":acceptline:${alcontext}" compwarnfmt msg

      if [[ -z ${msg} ]] ; then
        msg="%c will not execute and completion %f exists."
      fi

      zformat -f msg "${msg}" "c:${com}" "f:${fname}"

      zle -M -- "${msg}"
    fi
    return
  elif [[ -n ${buf//[$' \t\n']##/} ]] ; then
    # If we are here, the commandline contains something that is not
    # executable, which is neither subject to _command_name correction
    # and is not empty. might be a variable assignment
    alcontext='misc'
    Accept-Line-HandleContext

    return
  fi

  # If we got this far, the commandline only contains whitespace, or is empty.
  alcontext='empty'
  Accept-Line-HandleContext
}

zle -N accept-line
zle -N Accept-Line
zle -N Accept-Line-HandleContext

# power completion / abbreviation expansion / buffer expansion
# see http://zshwiki.org/home/examples/zleiab for details
# less risky than the global aliases but powerful as well
# just type the abbreviation key and afterwards 'ctrl-x .' to expand it
declare -A abk
setopt extendedglob
setopt interactivecomments
abk=(
#   key   # value                  (#d additional doc string)
#A# start
  '...'  '../..'
  '....' '../../..'
  'BG'   '& exit'
  'C'    '| wc -l'
  'G'    '|& rg '${rg_options:+"${rg_options[*]}"}
  'H'    '| head'
  'Hl'   ' --help |& less -r'    #d (Display help in pager)
  'L'    '| less'
  'LL'   '|& less -r'
  'M'    '| most'
  'N'    '&>/dev/null'           #d (No Output)
  'R'    '| tr A-z N-za-m'       #d (ROT13)
  'SL'   '| sort | less'
  'S'    '| sort -u'
  'T'    '| tail'
  'V'    '|& vim -'
#A# end
  'co'   './configure && make && sudo make install'
)

function zleiab () {
  emulate -L zsh
  setopt extendedglob
  local MATCH

  LBUFFER=${LBUFFER%%(#m)[.\-+:|_a-zA-Z0-9]#}
  LBUFFER+=${abk[$MATCH]:-$MATCH}
}

zle -N zleiab

function help-show-abk () {
  zle -M "$(print "Available abbreviations for expansion:"; print -a -C 2 ${(kv)abk})"
}

zle -N help-show-abk

# press "ctrl-x d" to insert the actual date in the form yyyy-mm-dd
function insert-datestamp () { LBUFFER+=${(%):-'%D{%Y-%m-%d}'}; }
zle -N insert-datestamp

function grml-zsh-fg () {
  if (( ${#jobstates} )); then
    zle .push-input
    [[ -o hist_ignore_space ]] && BUFFER=' ' || BUFFER=''
    BUFFER="${BUFFER}fg"
    zle .accept-line
  else
    zle -M 'No background jobs. Doing nothing.'
  fi
}
zle -N grml-zsh-fg

# run command line as user root via sudo:
function sudo-command-line () {
  [[ -z $BUFFER ]] && zle up-history
  if [[ $BUFFER != sudo\ * ]]; then
    BUFFER="sudo $BUFFER"
    CURSOR=$(( CURSOR+5 ))
  fi
}
zle -N sudo-command-line

### jump behind the first word on the cmdline.
### useful to add options.
function jump_after_first_word () {
  local words
  words=(${(z)BUFFER})

  if (( ${#words} <= 1 )) ; then
    CURSOR=${#BUFFER}
  else
    CURSOR=${#${words[1]}}
  fi
}
zle -N jump_after_first_word

#f5# Create directory under cursor or the selected area
function inplaceMkDirs () {
  # Press ctrl-xM to create the directory under the cursor or the selected area.
  # To select an area press ctrl-@ or ctrl-space and use the cursor.
  # Use case: you type "mv abc ~/testa/testb/testc/" and remember that the
  # directory does not exist yet -> press ctrl-XM and problem solved
  local PATHTOMKDIR
  if ((REGION_ACTIVE==1)); then
    local F=$MARK T=$CURSOR
    if [[ $F -gt $T ]]; then
      F=${CURSOR}
      T=${MARK}
    fi
    # get marked area from buffer and eliminate whitespace
    PATHTOMKDIR=${BUFFER[F+1,T]%%[[:space:]]##}
    PATHTOMKDIR=${PATHTOMKDIR##[[:space:]]##}
  else
    local bufwords iword
    bufwords=(${(z)LBUFFER})
    iword=${#bufwords}
    bufwords=(${(z)BUFFER})
    PATHTOMKDIR="${(Q)bufwords[iword]}"
  fi
  [[ -z "${PATHTOMKDIR}" ]] && return 1
  PATHTOMKDIR=${~PATHTOMKDIR}
  if [[ -e "${PATHTOMKDIR}" ]]; then
    zle -M " path already exists, doing nothing"
  else
    zle -M "$(mkdir -p -v "${PATHTOMKDIR}")"
    zle end-of-line
  fi
}
zle -N inplaceMkDirs

#v1# set number of lines to display per page
HELP_LINES_PER_PAGE=20
#v1# set location of help-zle cache file
HELP_ZLE_CACHE_FILE=~/.cache/zsh_help_zle_lines.zsh
# helper function for help-zle, actually generates the help text
function help_zle_parse_keybindings () {
  emulate -L zsh
  setopt extendedglob
  unsetopt ksharrays  #indexing starts at 1

  #v1# choose files that help-zle will parse for keybindings
  ((${+HELPZLE_KEYBINDING_FILES})) || HELPZLE_KEYBINDING_FILES=( /etc/zsh/zshrc ~/.zshrc.pre ~/.zshrc ~/.zshrc.local )

  if [[ -r $HELP_ZLE_CACHE_FILE ]]; then
    local load_cache=0
    local f
    for f ($HELPZLE_KEYBINDING_FILES) [[ $f -nt $HELP_ZLE_CACHE_FILE ]] && load_cache=1
    [[ $load_cache -eq 0 ]] && . $HELP_ZLE_CACHE_FILE && return
  fi

  #fill with default keybindings, possibly to be overwritten in a file later
  #Note that due to zsh inconsistency on escaping assoc array keys, we encase the key in '' which we will remove later
  local -A help_zle_keybindings
  help_zle_keybindings['<Ctrl>@']="set MARK"
  help_zle_keybindings['<Ctrl>x<Ctrl>j']="vi-join lines"
  help_zle_keybindings['<Ctrl>x<Ctrl>b']="jump to matching brace"
  help_zle_keybindings['<Ctrl>x<Ctrl>u']="undo"
  help_zle_keybindings['<Ctrl>_']="undo"
  help_zle_keybindings['<Ctrl>x<Ctrl>f<c>']="find <c> in cmdline"
  help_zle_keybindings['<Ctrl>a']="goto beginning of line"
  help_zle_keybindings['<Ctrl>e']="goto end of line"
  help_zle_keybindings['<Ctrl>t']="transpose charaters"
  help_zle_keybindings['<Alt>t']="transpose words"
  help_zle_keybindings['<Alt>s']="spellcheck word"
  help_zle_keybindings['<Ctrl>k']="backward kill buffer"
  help_zle_keybindings['<Ctrl>u']="forward kill buffer"
  help_zle_keybindings['<Ctrl>y']="insert previously killed word/string"
  help_zle_keybindings["<Alt>'"]="quote line"
  help_zle_keybindings['<Alt>"']="quote from mark to cursor"
  help_zle_keybindings['<Alt><arg>']="repeat next cmd/char <arg> times (<Alt>-<Alt>1<Alt>0a -> -10 times 'a')"
  help_zle_keybindings['<Alt>u']="make next word Uppercase"
  help_zle_keybindings['<Alt>l']="make next word lowercase"
  help_zle_keybindings['<Ctrl>xG']="preview expansion under cursor"
  help_zle_keybindings['<Alt>q']="push current CL into background, freeing it. Restore on next CL"
  help_zle_keybindings['<Alt>.']="insert (and interate through) last word from prev CLs"
  help_zle_keybindings['<Alt>,']="complete word from newer history (consecutive hits)"
  help_zle_keybindings['<Alt>m']="repeat last typed word on current CL"
  help_zle_keybindings['<Ctrl>v']="insert next keypress symbol literally (e.g. for bindkey)"
  help_zle_keybindings['!!:n*<Tab>']="insert last n arguments of last command"
  help_zle_keybindings['!!:n-<Tab>']="insert arguments n..N-2 of last command (e.g. mv s s d)"
  help_zle_keybindings['<Alt>h']="show help/manpage for current command"

  #init global variables
  unset help_zle_lines help_zle_sln
  typeset -g -a help_zle_lines
  typeset -g help_zle_sln=1

  local k v f cline
  local lastkeybind_desc contents     #last description starting with #k# that we found
  local num_lines_elapsed=0            #number of lines between last description and keybinding
  #search config files in the order they a called (and thus the order in which they overwrite keybindings)
  for f in $HELPZLE_KEYBINDING_FILES; do
    [[ -r "$f" ]] || continue   #not readable ? skip it
    contents="$(<$f)"
    for cline in "${(f)contents}"; do
      #zsh pattern: matches lines like: #k# ..............
      if [[ "$cline" == (#s)[[:space:]]#\#k\#[[:space:]]##(#b)(*)[[:space:]]#(#e) ]]; then
        lastkeybind_desc="$match[*]"
        num_lines_elapsed=0
      #zsh pattern: matches lines that set a keybinding using bind2map, bindkey or compdef -k
      #             ignores lines that are commentend out
      #             grabs first in '' or "" enclosed string with length between 1 and 6 characters
      elif [[ "$cline" == [^#]#(bind2maps[[:space:]](*)-s|bindkey|compdef -k)[[:space:]](*)(#b)(\"((?)(#c1,6))\"|\'((?)(#c1,6))\')(#B)(*)  ]]; then
        #description previously found ? description not more than 2 lines away ? keybinding not empty ?
        if [[ -n $lastkeybind_desc && $num_lines_elapsed -lt 2 && -n $match[1] ]]; then
          #substitute keybinding string with something readable
          k=${${${${${${${match[1]/\\e\^h/<Alt><BS>}/\\e\^\?/<Alt><BS>}/\\e\[5~/<PageUp>}/\\e\[6~/<PageDown>}//(\\e|\^\[)/<Alt>}//\^/<Ctrl>}/3~/<Alt><Del>}
          #put keybinding in assoc array, possibly overwriting defaults or stuff found in earlier files
          #Note that we are extracting the keybinding-string including the quotes (see Note at beginning)
          help_zle_keybindings[${k}]=$lastkeybind_desc
        fi
        lastkeybind_desc=""
      else
        ((num_lines_elapsed++))
      fi
    done
  done
  unset contents
  #calculate length of keybinding column
  local kstrlen=0
  for k (${(k)help_zle_keybindings[@]}) ((kstrlen < ${#k})) && kstrlen=${#k}
  #convert the assoc array into preformated lines, which we are able to sort
  for k v in ${(kv)help_zle_keybindings[@]}; do
    #pad keybinding-string to kstrlen chars and remove outermost characters (i.e. the quotes)
    help_zle_lines+=("${(r:kstrlen:)k[2,-2]}${v}")
  done
  #sort lines alphabetically
  help_zle_lines=("${(i)help_zle_lines[@]}")
  [[ -d ${HELP_ZLE_CACHE_FILE:h} ]] || mkdir -p "${HELP_ZLE_CACHE_FILE:h}"
  echo "help_zle_lines=(${(q)help_zle_lines[@]})" >| $HELP_ZLE_CACHE_FILE
  zcompile $HELP_ZLE_CACHE_FILE
}
typeset -g help_zle_sln
typeset -g -a help_zle_lines

# Provides (partially autogenerated) help on keybindings and the zsh line editor
function help-zle () {
  emulate -L zsh
  unsetopt ksharrays  #indexing starts at 1
  #help lines already generated ? no ? then do it
  [[ ${+functions[help_zle_parse_keybindings]} -eq 1 ]] && {help_zle_parse_keybindings && unfunction help_zle_parse_keybindings}
  #already displayed all lines ? go back to the start
  [[ $help_zle_sln -gt ${#help_zle_lines} ]] && help_zle_sln=1
  local sln=$help_zle_sln
  #note that help_zle_sln is a global var, meaning we remember the last page we viewed
  help_zle_sln=$((help_zle_sln + HELP_LINES_PER_PAGE))
  zle -M "${(F)help_zle_lines[sln,help_zle_sln-1]}"
}
zle -N help-zle

## complete word from currently visible Screen or Tmux buffer.
if check_com -c screen || check_com -c tmux; then
    function _complete_screen_display () {
        [[ "$TERM" != "screen" ]] && return 1

        local TMPFILE=$(mktemp)
        local -U -a _screen_display_wordlist
        trap "rm -f $TMPFILE" EXIT

        # fill array with contents from screen hardcopy
        if ((${+TMUX})); then
            #works, but crashes tmux below version 1.4
            #luckily tmux -V option to ask for version, was also added in 1.4
            tmux -V &>/dev/null || return
            tmux -q capture-pane \; save-buffer -b 0 $TMPFILE \; delete-buffer -b 0
        else
            screen -X hardcopy $TMPFILE
            # screen sucks, it dumps in latin1, apparently always. so recode it
            # to system charset
            check_com recode && recode latin1 $TMPFILE
        fi
        _screen_display_wordlist=( ${(QQ)$(<$TMPFILE)} )
        # remove PREFIX to be completed from that array
        _screen_display_wordlist[${_screen_display_wordlist[(i)$PREFIX]}]=""
        compadd -a _screen_display_wordlist
    }
    #m# k CTRL-x\,\,\,S Complete word from GNU screen buffer
    bindkey -r "^xS"
    compdef -k _complete_screen_display complete-word '^xS'
fi

# Load a few more functions and tie them to widgets, so they can be bound:

function zrcautozle () {
  emulate -L zsh
  local fnc=$1
  zrcautoload $fnc && zle -N $fnc
}

function zrcgotwidget () {
  (( ${+widgets[$1]} ))
}

zrcautozle insert-files
zrcautozle edit-command-line
zrcautozle insert-unicode-char
if zrcautoload history-search-end; then
  zle -N history-beginning-search-backward-end history-search-end
  zle -N history-beginning-search-forward-end  history-search-end
fi
zle -C hist-complete complete-word _generic
zstyle ':completion:hist-complete:*' completer _history

# The actual terminal setup hooks and bindkey-calls:

function zrcbindkey () {
  if (( ARGC )) && zrcgotwidget ${argv[-1]}; then
    bindkey "$@"
  fi
}

function bind2maps () {
  local i sequence widget
  local -a maps

  while [[ "$1" != "--" ]]; do
      maps+=( "$1" )
      shift
  done
  shift

  if [[ "$1" == "-s" ]]; then
      shift
      sequence="$1"
  else
      sequence="${key[$1]}"
  fi
  widget="$2"

  [[ -z "$sequence" ]] && return 1

  for i in "${maps[@]}"; do
      zrcbindkey -M "$i" "$sequence" "$widget"
  done
}

if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-smkx () {
    emulate -L zsh
    printf '%s' ${terminfo[smkx]}
  }
  function zle-rmkx () {
    emulate -L zsh
    printf '%s' ${terminfo[rmkx]}
  }
  function zle-line-init () {
    zle-smkx
  }
  function zle-line-finish () {
    zle-rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

typeset -A key
key=(
  Home     "${terminfo[khome]}"
  End      "${terminfo[kend]}"
  Insert   "${terminfo[kich1]}"
  Delete   "${terminfo[kdch1]}"
  Up       "${terminfo[kcuu1]}"
  Down     "${terminfo[kcud1]}"
  Left     "${terminfo[kcub1]}"
  Right    "${terminfo[kcuf1]}"
  PageUp   "${terminfo[kpp]}"
  PageDown "${terminfo[knp]}"
  BackTab  "${terminfo[kcbt]}"
)

# Guidelines for adding key bindings:
#
#   - Do not add hardcoded escape sequences, to enable non standard key
#     combinations such as Ctrl-Meta-Left-Cursor. They are not easily portable.
#
#   - Adding Ctrl characters, such as '^b' is okay; note that '^b' and '^B' are
#     the same key.
#
#   - All keys from the $key[] mapping are obviously okay.
#
#   - Most terminals send "ESC x" when Meta-x is pressed. Thus, sequences like
#     '\ex' are allowed in here as well.

bind2maps       viins vicmd -- Home   vi-beginning-of-line
bind2maps       viins vicmd -- End    vi-end-of-line
bind2maps       viins       -- Insert overwrite-mode
bind2maps             vicmd -- Insert vi-insert
bind2maps                   -- Delete delete-char
bind2maps       viins vicmd -- Delete vi-delete-char
bind2maps       viins vicmd -- Up     up-line-or-search
bind2maps       viins vicmd -- Down   down-line-or-search
bind2maps                   -- Left   backward-char
bind2maps       viins vicmd -- Left   vi-backward-char
bind2maps                   -- Right  forward-char
bind2maps       viins vicmd -- Right  vi-forward-char
#k# Perform abbreviation expansion
bind2maps       viins       -- -s '^x.' zleiab
#k# Display list of abbreviations that would expand
bind2maps       viins       -- -s '^xb' help-show-abk
#k# mkdir -p <dir> from string under cursor or marked area
bind2maps       viins       -- -s '^xM' inplaceMkDirs
#k# display help for keybindings and ZLE
bind2maps       viins       -- -s '^xz' help-zle
#k# Insert files and test globbing
bind2maps       viins       -- -s "^xf" insert-files
#k# Edit the current line in \kbd{\$EDITOR}
bind2maps       viins       -- -s '\ee' edit-command-line
#k# search history backward for entry beginning with typed text
bind2maps       viins       -- -s '^xp' history-beginning-search-backward-end
#k# search history forward for entry beginning with typed text
bind2maps       viins       -- -s '^xP' history-beginning-search-forward-end
#k# search history backward for entry beginning with typed text
bind2maps       viins       -- PageUp history-beginning-search-backward-end
#k# search history forward for entry beginning with typed text
bind2maps       viins       -- PageDown history-beginning-search-forward-end
bind2maps       viins       -- -s "^x^h" commit-to-history
#k# Kill left-side word or everything up to next slash
bind2maps       viins       -- -s '\ev' slash-backward-kill-word
#k# Kill left-side word or everything up to next slash
bind2maps       viins       -- -s '\e^h' slash-backward-kill-word
#k# Kill left-side word or everything up to next slash
bind2maps       viins       -- -s '\e^?' slash-backward-kill-word
# Do history expansion on space:
bind2maps       viins       -- -s ' ' magic-space
#k# Trigger menu-complete
bind2maps       viins       -- -s '\ei' menu-complete  # menu completion via esc-i
#k# Insert a timestamp on the command line (yyyy-mm-dd)
bind2maps       viins       -- -s '^xd' insert-datestamp
#k# Insert last typed word
bind2maps       viins       -- -s "\em" insert-last-typed-word
#k# A smart shortcut for \kbd{fg<enter>}
bind2maps       viins       -- -s '^z' grml-zsh-fg
#k# prepend the current command with "sudo"
bind2maps       viins       -- -s "^os" sudo-command-line
#k# jump to after first word (for adding options)
bind2maps       viins       -- -s '^x1' jump_after_first_word
#k# complete word from history with menu
bind2maps       viins       -- -s "^x^x" hist-complete

# insert unicode character
# usage example: 'ctrl-x i' 00A7 'ctrl-x i' will give you an §
# See for example http://unicode.org/charts/ for unicode characters code
#k# Insert Unicode character
bind2maps       viins       -- -s '^xi' insert-unicode-char

# use the new *-pattern-* widgets for incremental history search
if zrcgotwidget history-incremental-pattern-search-backward; then
  for seq wid in '^r' history-incremental-pattern-search-backward \
                 '^s' history-incremental-pattern-search-forward
  do
    bind2maps       viins vicmd -- -s $seq $wid
  done
  builtin unset -v seq wid
fi

# Finally, here are still a few hardcoded escape sequences; Special sequences
# like Ctrl-<Cursor-key> etc do suck a fair bit, because they are not
# standardised and most of the time are not available in a terminals terminfo
# entry.
#
# While we do not encourage adding bindings like these, we will keep these for
# backward compatibility.

## use Ctrl-left-arrow and Ctrl-right-arrow for jumping to word-beginnings on
## the command line.
# URxvt sequences:
bind2maps       viins vicmd -- -s '\eOc' forward-word
bind2maps       viins vicmd -- -s '\eOd' backward-word
# These are for xterm:
bind2maps       viins vicmd -- -s '\e[1;5C' forward-word
bind2maps       viins vicmd -- -s '\e[1;5D' backward-word
## the same for alt-left-arrow and alt-right-arrow
# URxvt again:
bind2maps       viins vicmd -- -s '\e\e[C' forward-word
bind2maps       viins vicmd -- -s '\e\e[D' backward-word
# Xterm again:
bind2maps       viins vicmd -- -s '^[[1;3C' forward-word
bind2maps       viins vicmd -- -s '^[[1;3D' backward-word
# Also try ESC Left/Right:
bind2maps       viins vicmd -- -s '\e'${key[Right]} forward-word
bind2maps       viins vicmd -- -s '\e'${key[Left]}  backward-word

# autoloading

zrcautoload zmv
zrcautoload zed

# we don't want to quote/espace URLs on our own...
# if autoload -U url-quote-magic ; then
#    zle -N self-insert url-quote-magic
#    zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
# else
#    print 'Notice: no url-quote-magic available :('
# fi
alias url-quote='autoload -U url-quote-magic ; zle -N self-insert url-quote-magic'

#m# k ESC-h Call \kbd{run-help} for the 1st word on the command line
alias run-help >&/dev/null && unalias run-help
for rh in run-help{,-git,-ip,-openssl,-p4,-sudo,-svk,-svn}; do
  zrcautoload $rh
done; unset rh

# history

#v#
HISTFILE=${ZDOTDIR:-${HOME}}/.zsh_history

# dirstack handling

DIRSTACKSIZE=${DIRSTACKSIZE:-20}
DIRSTACKFILE=${DIRSTACKFILE:-${ZDOTDIR:-${HOME}}/.zdirs}

# set variable debian_chroot if running in a chroot with /etc/debian_chroot
if [[ -z "$debian_chroot" ]] && [[ -r /etc/debian_chroot ]] ; then
  debian_chroot=$(</etc/debian_chroot)
fi

# do we have GNU ls with color-support?
if [[ "$TERM" != dumb ]]; then
  #a1# List files with colors (\kbd{ls \ldots})
  alias ls="command ls ${ls_options:+${ls_options[*]}}"
  #a1# List all files, with colors (\kbd{ls -la \ldots})
  alias la="command ls -la ${ls_options:+${ls_options[*]}}"
  #a1# List files with long colored list, without dotfiles (\kbd{ls -l \ldots})
  alias ll="command ls -l ${ls_options:+${ls_options[*]}}"
  #a1# List files with long colored list, human readable sizes (\kbd{ls -hAl \ldots})
  alias lh="command ls -hAl ${ls_options:+${ls_options[*]}}"
  #a1# List files with long colored list, append qualifier to filenames (\kbd{ls -l \ldots})\\&\quad(\kbd{/} for directories, \kbd{@} for symlinks ...)
  alias l="command ls -l ${ls_options:+${ls_options[*]}}"
else
  alias la='command ls -la'
  alias ll='command ls -l'
  alias lh='command ls -hAl'
  alias l='command ls -l'
fi

if [[ -r /proc/mdstat ]]; then
  alias mdstat='cat /proc/mdstat'
fi

# see http://www.cl.cam.ac.uk/~mgk25/unicode.html#term for details
alias term2iso="echo 'Setting terminal to iso mode' ; print -n '\e%@'"
alias term2utf="echo 'Setting terminal to utf-8 mode'; print -n '\e%G'"

# make sure it is not assigned yet
[[ -n ${aliases[utf2iso]} ]] && unalias utf2iso
function utf2iso () {
  if isutfenv ; then
    local ENV
    for ENV in $(env | command rg -i '.utf') ; do
      eval export "$(echo $ENV | sed 's/UTF-8/iso885915/ ; s/utf8/iso885915/')"
    done
  fi
}

# make sure it is not assigned yet
[[ -n ${aliases[iso2utf]} ]] && unalias iso2utf
function iso2utf () {
  if ! isutfenv ; then
    local ENV
    for ENV in $(env | command rg -i '\.iso') ; do
      eval export "$(echo $ENV | sed 's/iso.*/UTF-8/ ; s/ISO.*/UTF-8/')"
    done
  fi
}

# especially for roadwarriors using GNU screen and ssh:
if ! check_com asc &>/dev/null ; then
  function asc () { autossh -t "$@" 'screen -RdU' }
  compdef asc=ssh
fi

# debian stuff
if [[ -r /etc/debian_version ]] ; then
  if [[ -z "$GRML_NO_APT_ALIASES" ]]; then
    #a3# Execute \kbd{apt-cache policy}
    alias acp='apt-cache policy'
    if check_com -c apt ; then
      #a3# Execute \kbd{apt search}
      alias acs='apt search'
      #a3# Execute \kbd{apt show}
      alias acsh='apt show'
      #a3# Execute \kbd{apt dist-upgrade}
      salias adg="apt dist-upgrade"
      #a3# Execute \kbd{apt upgrade}
      salias ag="apt upgrade"
      #a3# Execute \kbd{apt install}
      salias agi="apt install"
      #a3# Execute \kbd{apt update}
      salias au="apt update"
    else
      alias acs='apt-cache search'
      alias acsh='apt-cache show'
      salias adg="apt-get dist-upgrade"
      salias ag="apt-get upgrade"
      salias agi="apt-get install"
      salias au="apt-get update"
    fi
    #a3# Execute \kbd{aptitude install}
    salias ati="aptitude install"
    #a3# Execute \kbd{aptitude update ; aptitude safe-upgrade}
    salias -a up="aptitude update ; aptitude safe-upgrade"
    #a3# Execute \kbd{dpkg-buildpackage}
    alias dbp='dpkg-buildpackage'
    #a3# Execute \kbd{rg-excuses}
    alias ge='rg-excuses'
  fi
fi

# use /var/log/syslog iff present, fallback to journalctl otherwise
if [ -e /var/log/syslog ] ; then
  #a1# Take a look at the syslog: \kbd{\$PAGER /var/log/syslog || journalctl}
  salias llog="$PAGER /var/log/syslog"     # take a look at the syslog
  #a1# Take a look at the syslog: \kbd{tail -f /var/log/syslog || journalctl}
  salias tlog="tail -f /var/log/syslog"    # follow the syslog
elif check_com -c journalctl ; then
  salias llog="journalctl"
  salias tlog="journalctl -f"
fi

# sort installed Debian-packages by size
if check_com -c dpkg-query ; then
  #a3# List installed Debian-packages sorted by size
  alias debs-by-size="dpkg-query -Wf 'x \${Installed-Size} \${Package} \${Status}\n' | sed -ne '/^x  /d' -e '/^x \(.*\) install ok installed$/s//\1/p' | sort -nr"
fi

# if cdrecord is a symlink (to wodim) or isn't present at all warn:
if [[ -L /usr/bin/cdrecord ]] || ! check_com -c cdrecord; then
  if check_com -c wodim; then
    function cdrecord () {
      <<__EOF0__
cdrecord is not provided under its original name by Debian anymore.
See #377109 in the BTS of Debian for more details.

Please use the wodim binary instead
__EOF0__
      return 1
    }
  fi
fi

#f1# Reload an autoloadable function
function freload () { while (( $# )); do; unfunction $1; autoload -U $1; shift; done }
compdef _functions freload

#
# Usage:
#
#      e.g.:   a -> b -> c -> d  ....
#
#      sll a
#
#
#      if parameter is given with leading '=', lookup $PATH for parameter and resolve that
#
#      sll =java
#
#      Note: limit for recursive symlinks on linux:
#            http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/fs/namei.c?id=refs/heads/master#l808
#            This limits recursive symlink follows to 8,
#            while limiting consecutive symlinks to 40.
#
#      When resolving and displaying information about symlinks, no check is made
#      that the displayed information does make any sense on your OS.
#      We leave that decission to the user.
#
#      The zstat module is used to detect symlink loops. zstat is available since zsh4.
#      With an older zsh you will need to abort with <C-c> in that case.
#      When a symlink loop is detected, a warning ist printed and further processing is stopped.
#
#      Module zstat is loaded by default in grml zshrc, no extra action needed for that.
#
#      Known bugs:
#      If you happen to come across a symlink that points to a destination on another partition
#      with the same inode number, that will be marked as symlink loop though it is not.
#      Two hints for this situation:
#      I)  Play lottery the same day, as you seem to be rather lucky right now.
#      II) Send patches.
#
#      return status:
#      0 upon success
#      1 file/dir not accesible
#      2 symlink loop detected
#
#f1# List symlinks in detail (more detailed version of 'readlink -f', 'whence -s' and 'namei -l')
function sll () {
  if [[ -z ${1} ]] ; then
    printf 'Usage: %s <symlink(s)>\n' "${0}"
    return 1
  fi

  local file jumpd curdir
  local -i 10 RTN LINODE i
  local -a    SEENINODES
  curdir="${PWD}"
  RTN=0

  for file in "${@}" ; do
    SEENINODES=()
    ls -l "${file:a}" || RTN=1

    while [[ -h "$file" ]] ; do
      jumpd="${file:h}"
      file="${file:t}"

      if [[ -d ${jumpd} ]] ; then
        builtin cd -q "${jumpd}" || RTN=1
      fi
      file=$(readlink "$file")

      jumpd="${file:h}"
      file="${file:t}"

      if [[ -d ${jumpd} ]] ; then
        builtin cd -q "${jumpd}" || RTN=1
      fi

      ls -l "${PWD}/${file}" || RTN=1
    done
    shift 1
    if (( ${#} >= 1 )) ; then
        print ""
    fi
    builtin cd -q "${curdir}"
  done
  return ${RTN}
}

if check_com -c $PAGER ; then
  #f3# View Debian's changelog of given package(s)
  function dchange () {
    emulate -L zsh
    [[ -z "$1" ]] && printf 'Usage: %s <package_name(s)>\n' "$0" && return 1

    local package

    # `less` as $PAGER without e.g. `|lesspipe %s` inside $LESSOPEN can't properly
    # read *.gz files, try to detect this to use vi instead iff available
    local viewer

    if [[ ${$(typeset -p PAGER)[2]} = -a ]] ; then
      viewer=($PAGER)    # support PAGER=(less -Mr) but leave array untouched
    else
      viewer=(${=PAGER}) # support PAGER='less -Mr'
    fi

    if [[ ${viewer[1]:t} = less ]] && [[ -z "${LESSOPEN}" ]] && check_com vi ; then
      viewer='vi'
    fi

    for package in "$@" ; do
      if [[ -r /usr/share/doc/${package}/changelog.Debian.gz ]] ; then
        $viewer /usr/share/doc/${package}/changelog.Debian.gz
      elif [[ -r /usr/share/doc/${package}/changelog.gz ]] ; then
        $viewer /usr/share/doc/${package}/changelog.gz
      elif [[ -r /usr/share/doc/${package}/changelog ]] ; then
        $viewer /usr/share/doc/${package}/changelog
      else
        if check_com -c aptitude ; then
          echo "No changelog for package $package found, using aptitude to retrieve it."
          aptitude changelog "$package"
        elif check_com -c apt-get ; then
          echo "No changelog for package $package found, using apt-get to retrieve it."
          apt-get changelog "$package"
        else
          echo "No changelog for package $package found, sorry."
        fi
      fi
    done
  }
  function _dchange () { _files -W /usr/share/doc -/ }
  compdef _dchange dchange

  #f3# View Debian's NEWS of a given package
  function dnews () {
    emulate -L zsh
    if [[ -r /usr/share/doc/$1/NEWS.Debian.gz ]] ; then
      $PAGER /usr/share/doc/$1/NEWS.Debian.gz
    else
      if [[ -r /usr/share/doc/$1/NEWS.gz ]] ; then
        $PAGER /usr/share/doc/$1/NEWS.gz
      else
        echo "No NEWS file for package $1 found, sorry."
        return 1
      fi
    fi
  }
  function _dnews () { _files -W /usr/share/doc -/ }
  compdef _dnews dnews

  #f3# View Debian's copyright of a given package
  function dcopyright () {
    emulate -L zsh
    if [[ -r /usr/share/doc/$1/copyright ]] ; then
      $PAGER /usr/share/doc/$1/copyright
    else
      echo "No copyright file for package $1 found, sorry."
      return 1
    fi
  }
  function _dcopyright () { _files -W /usr/share/doc -/ }
  compdef _dcopyright dcopyright

  #f3# View upstream's changelog of a given package
  function uchange () {
    emulate -L zsh
    if [[ -r /usr/share/doc/$1/changelog.gz ]] ; then
      $PAGER /usr/share/doc/$1/changelog.gz
    else
      echo "No changelog for package $1 found, sorry."
      return 1
    fi
  }
  function _uchange () { _files -W /usr/share/doc -/ }
  compdef _uchange uchange
fi

# zsh profiling
function profile () {
  ZSH_PROFILE_RC=1 zsh "$@"
}

#f1# Edit an alias via zle
function edalias () {
  [[ -z "$1" ]] && { echo "Usage: edalias <alias_to_edit>" ; return 1 } || vared aliases'[$1]' ;
}
compdef _aliases edalias

#f1# Edit a function via zle
function edfunc () {
  [[ -z "$1" ]] && { echo "Usage: edfunc <function_to_edit>" ; return 1 } || zed -f "$1" ;
}
compdef _functions edfunc

# use it e.g. via 'Restart apache2'
#m# f6 Start() \kbd{service \em{process}}\quad\kbd{start}
#m# f6 Restart() \kbd{service \em{process}}\quad\kbd{restart}
#m# f6 Stop() \kbd{service \em{process}}\quad\kbd{stop}
#m# f6 Reload() \kbd{service \em{process}}\quad\kbd{reload}
#m# f6 Force-Reload() \kbd{service \em{process}}\quad\kbd{force-reload}
#m# f6 Status() \kbd{service \em{process}}\quad\kbd{status}
if [[ -d /etc/init.d || -d /etc/service ]] ; then
  function __start_stop () {
    local action_="${1:l}"  # e.g Start/Stop/Restart
    local service_="$2"
    local param_="$3"

    local service_target_="$(readlink /etc/init.d/$service_)"
    if [[ $service_target_ == "/usr/bin/sv" ]]; then
      # runit
      case "${action_}" in
        start) \
          if [[ ! -e /etc/service/$service_ ]]; then
            $SUDO ln -s "/etc/sv/$service_" "/etc/service/"
          else
            $SUDO "/etc/init.d/$service_" "${action_}" "$param_"
          fi ;;
        # there is no reload in runits sysv emulation
        reload) $SUDO "/etc/init.d/$service_" "force-reload" "$param_" ;;
        *) $SUDO "/etc/init.d/$service_" "${action_}" "$param_" ;;
      esac
    else
      # sysv/sysvinit-utils, upstart
      if check_com -c service ; then
        $SUDO service "$service_" "${action_}" "$param_"
      else
        $SUDO "/etc/init.d/$service_" "${action_}" "$param_"
      fi
    fi
  }

  for i in Start Restart Stop Force-Reload Reload Status ; do
      eval "function $i () { __start_stop $i \"\$1\" \"\$2\" ; }"
  done
  builtin unset -v i
fi

#f1# Provides useful information on globbing
function H-Glob () {
  echo -e "
  /      directories
  .      plain files
  @      symbolic links
  =      sockets
  p      named pipes (FIFOs)
  *      executable plain files (0100)
  %      device files (character or block special)
  %b     block special files
  %c     character special files
  r      owner-readable files (0400)
  w      owner-writable files (0200)
  x      owner-executable files (0100)
  A      group-readable files (0040)
  I      group-writable files (0020)
  E      group-executable files (0010)
  R      world-readable files (0004)
  W      world-writable files (0002)
  X      world-executable files (0001)
  s      setuid files (04000)
  S      setgid files (02000)
  t      files with the sticky bit (01000)

  print *(m-1)          # Files modified up to a day ago
  print *(a1)           # Files accessed a day ago
  print *(@)            # Just symlinks
  print *(Lk+50)        # Files bigger than 50 kilobytes
  print *(Lk-50)        # Files smaller than 50 kilobytes
  print **/*.c          # All *.c files recursively starting in \$PWD
  print **/*.c~file.c   # Same as above, but excluding 'file.c'
  print (foo|bar).*     # Files starting with 'foo' or 'bar'
  print *~*.*           # All Files that do not contain a dot
  chmod 644 *(.^x)      # make all plain non-executable files publically readable
  print -l *(.c|.h)     # Lists *.c and *.h
  print **/*(g:users:)  # Recursively match all files that are owned by group 'users'
  echo /proc/*/cwd(:h:t:s/self//) # Analogous to >ps ax | awk '{print $1}'<"
}
alias help-zshglob=H-Glob

# rg for running process, like: 'any vim'
function any () {
  emulate -L zsh
  unsetopt KSH_ARRAYS
  if [[ -z "$1" ]] ; then
    echo "any - rg for process(es) by keyword" >&2
    echo "Usage: any <keyword>" >&2 ; return 1
  else
    ps xauwww | rg -i "${rg_options[@]}" "[${1[1]}]${1[2,-1]}"
  fi
}


# After resuming from suspend, system is paging heavily, leading to very bad interactivity.
# taken from $LINUX-KERNELSOURCE/Documentation/power/swsusp.txt
[[ -r /proc/1/maps ]] && \
function deswap () {
  print 'Reading /proc/[0-9]*/maps and sending output to /dev/null, this might take a while.'
  cat $(sed -ne 's:.* /:/:p' /proc/[0-9]*/maps | sort -u | rg -v '^/dev/')  > /dev/null
  print 'Finished, running "swapoff -a; swapon -a" may also be useful.'
}

# a wrapper for vim, that deals with title setting
#   VIM_OPTIONS
#       set this array to a set of options to vim you always want
#       to have set when calling vim (in .zshrc.local), like:
#           VIM_OPTIONS=( -p )
#       This will cause vim to send every file given on the
#       commandline to be send to it's own tab (needs vim7).
if check_com vim; then
  function vim () {
    VIM_PLEASE_SET_TITLE='yes' command vim ${VIM_OPTIONS} "$@"
  }
fi

ssl_hashes=( sha512 sha256 sha1 md5 )

for sh in ${ssl_hashes}; do
  eval 'ssl-cert-'${sh}'() {
    emulate -L zsh
    if [[ -z $1 ]] ; then
      printf '\''usage: %s <file>\n'\'' "ssh-cert-'${sh}'"
      return 1
    fi
    openssl x509 -noout -fingerprint -'${sh}' -in $1
  }'
done; unset sh

# make sure our environment is clean regarding colors
builtin unset -v BLUE RED GREEN CYAN YELLOW MAGENTA WHITE NO_COLOR

# load the lookup subsystem if it's available on the system
zrcautoload lookupinit && lookupinit

# set terminal property (used e.g. by msgid-chooser)
export COLORTERM="yes"

# general
# use colors when GNU rg with color-support
if (( $#rg_options > 0 )); then
  o=${rg_options:+"${rg_options[*]}"}
  #a2# Execute \kbd{rg -{}-color=auto}
  alias rg='rg '$o
  alias erg='erg '$o
  unset o
fi

# Usage: simple-extract <file>
# Using option -d deletes the original archive file.
#f5# Smart archive extractor
function simple-extract () {
  emulate -L zsh
  setopt extended_glob noclobber
  local ARCHIVE DELETE_ORIGINAL DECOMP_CMD USES_STDIN USES_STDOUT GZTARGET WGET_CMD
  local RC=0
  zparseopts -D -E "d=DELETE_ORIGINAL"
  for ARCHIVE in "${@}"; do
    case $ARCHIVE in
      *(tar.bz2|tbz2|tbz))
        DECOMP_CMD="tar -xvjf -"
        USES_STDIN=true
        USES_STDOUT=false
        ;;
      *(tar.gz|tgz))
        DECOMP_CMD="tar -xvzf -"
        USES_STDIN=true
        USES_STDOUT=false
        ;;
      *(tar.xz|txz|tar.lzma))
        DECOMP_CMD="tar -xvJf -"
        USES_STDIN=true
        USES_STDOUT=false
        ;;
      *tar.zst)
        DECOMP_CMD="tar --zstd -xvf -"
        USES_STDIN=true
        USES_STDOUT=false
        ;;
      *tar)
        DECOMP_CMD="tar -xvf -"
        USES_STDIN=true
        USES_STDOUT=false
        ;;
      *rar)
        DECOMP_CMD="unrar x"
        USES_STDIN=false
        USES_STDOUT=false
        ;;
      *lzh)
        DECOMP_CMD="lha x"
        USES_STDIN=false
        USES_STDOUT=false
        ;;
      *7z)
        DECOMP_CMD="7z x"
        USES_STDIN=false
        USES_STDOUT=false
        ;;
      *(zip|jar))
        DECOMP_CMD="unzip"
        USES_STDIN=false
        USES_STDOUT=false
        ;;
      *deb)
        DECOMP_CMD="ar -x"
        USES_STDIN=false
        USES_STDOUT=false
        ;;
      *bz2)
        DECOMP_CMD="bzip2 -d -c -"
        USES_STDIN=true
        USES_STDOUT=true
        ;;
      *(gz|Z))
        DECOMP_CMD="gzip -d -c -"
        USES_STDIN=true
        USES_STDOUT=true
        ;;
      *(xz|lzma))
        DECOMP_CMD="xz -d -c -"
        USES_STDIN=true
        USES_STDOUT=true
        ;;
      *zst)
        DECOMP_CMD="zstd -d -c -"
        USES_STDIN=true
        USES_STDOUT=true
        ;;
      *)
        print "ERROR: '$ARCHIVE' has unrecognized archive type." >&2
        RC=$((RC+1))
        continue
        ;;
    esac

    if ! check_com ${DECOMP_CMD[(w)1]}; then
      echo "ERROR: ${DECOMP_CMD[(w)1]} not installed." >&2
      RC=$((RC+2))
      continue
    fi

    GZTARGET="${ARCHIVE:t:r}"
    if [[ -f $ARCHIVE ]] ; then

      print "Extracting '$ARCHIVE' ..."
      if $USES_STDIN; then
        if $USES_STDOUT; then
          ${=DECOMP_CMD} < "$ARCHIVE" > $GZTARGET
        else
          ${=DECOMP_CMD} < "$ARCHIVE"
        fi
      else
        if $USES_STDOUT; then
            ${=DECOMP_CMD} "$ARCHIVE" > $GZTARGET
        else
            ${=DECOMP_CMD} "$ARCHIVE"
        fi
      fi
      [[ $? -eq 0 && -n "$DELETE_ORIGINAL" ]] && rm -f "$ARCHIVE"

    elif [[ "$ARCHIVE" == (#s)(https|http|ftp)://* ]] ; then
      if check_com curl; then
        WGET_CMD="curl -L -s -o -"
      elif check_com wget; then
        WGET_CMD="wget -q -O -"
      elif check_com fetch; then
        WGET_CMD="fetch -q -o -"
      else
        print "ERROR: neither wget, curl nor fetch is installed" >&2
        RC=$((RC+4))
        continue
      fi
      print "Downloading and Extracting '$ARCHIVE' ..."
      if $USES_STDIN; then
        if $USES_STDOUT; then
          ${=WGET_CMD} "$ARCHIVE" | ${=DECOMP_CMD} > $GZTARGET
          RC=$((RC+$?))
        else
          ${=WGET_CMD} "$ARCHIVE" | ${=DECOMP_CMD}
          RC=$((RC+$?))
        fi
      else
        if $USES_STDOUT; then
          ${=DECOMP_CMD} =(${=WGET_CMD} "$ARCHIVE") > $GZTARGET
        else
          ${=DECOMP_CMD} =(${=WGET_CMD} "$ARCHIVE")
        fi
      fi

    else
      print "ERROR: '$ARCHIVE' is neither a valid file nor a supported URI." >&2
      RC=$((RC+8))
    fi
  done
  return $RC
}

function __archive_or_uri () {
  _alternative \
    'files:Archives:_files -g "*.(#l)(tar.bz2|tbz2|tbz|tar.gz|tgz|tar.xz|txz|tar.lzma|tar|rar|lzh|7z|zip|jar|deb|bz2|gz|Z|xz|lzma)"' \
    '_urls:Remote Archives:_urls'
}

function _simple_extract () {
  _arguments \
    '-d[delete original archivefile after extraction]' \
    '*:Archive Or Uri:__archive_or_uri'
}
compdef _simple_extract simple-extract

# disable bracketed paste mode for dumb terminals
[[ "$TERM" == dumb ]] && unset zle_bracketed_paste

zrclocal

## END OF FILE #################################################################
# vim:filetype=zsh foldmethod=marker autoindent expandtab shiftwidth=4
# Local variables:
# mode: sh
# End:
