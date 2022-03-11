#!/usr/bin/env zsh

source $HOME/homebrew/bin/virtualenvwrapper.sh
workon jupyterlab
cd ~/Developer && jupyter-lab
