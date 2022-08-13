# `anhdle14` 's dotfiles

Setting up new machines quickly just like mine.

## Prerequisites

- Linux or Darwin (maybe Windows Subsystem for Linux?)
- `git`
- `chezmoi`

## FAQs & Golden Rules

1. How I choose where to put a setting for shell (zsh)?
   - If it is needed by a command run non-interactively: `.zshenv`
   - If it should be updated on each new shell: `.zshenv`
   - If it runs a command which may take some time to complete: `.zprofile`
   - If it is related to interactive usage: `.zshrc`
   - If it is a command to be run when the shell is fully setup: `.zlogin`
   - If it releases a resource acquired at login: `.zlogout`
