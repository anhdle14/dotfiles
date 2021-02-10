" ------------------------------------------------------------------------------
" vim: set ts=2 sw=2 tw=80 noet :

" ------------------------------------------------------------------------------
" Plug
" ------------------------------------------------------------------------------

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  "autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/autoload/plugged')

Plug 'ciaranm/securemodelines'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-vinegar'

call plug#end()

" ------------------------------------------------------------------------------
" General
" ------------------------------------------------------------------------------

set nocompatible
set termguicolors
set mouse=a
set clipboard+=unnamedplus
set expandtab smarttab
set incsearch ignorecase smartcase hlsearch
set tabstop=2 softtabstop=2 shiftwidth=2 cindent
set winaltkeys=no
set nowrap
set number
set relativenumber
set title
set noshowmode noshowcmd
set emoji
set grepprg=rg\ --vimgrep " Using ripgrep
set matchtime=2

" UI """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if &term =~ '256color' && $TMUX != ''
  " disable Background Color Erase (BCE) so that color schemes
  " render properly when inside 256-color tmux and GNU screen.
  " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
  set t_ut=
endif

" Persistent Undo """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set undofile
set undodir=~/.vim/tmp
if empty(glob('~/.vim/tmp'))
  silent! call mkdir(expand('~/.vim/tmp'), "p", 0755)
endif

" Backup """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set backup
set backupdir=~/.vim/backups
set writebackup
set backupext=.bak
set noswapfile
if empty(glob('~/.vim/backups'))
  silent! call mkdir(expand('~/.vim/backups'), "p", 0755)
endif

" Encoding """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('multi_byte')
  set encoding=utf-8
  set fileencoding=utf-8
  set fileencodings=ucs-bom,utf-8,gbk,gb18030,big5,euc-jp,latin1
endif

" FZF Hacks """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" > Search down into subfolder"
" > Provides tab-completion to all file-related tasks
set path+=**

" > Display all matching files when we tab complete
set wildmenu

" - Hit tab to :find by partial match
" - Use * to make it fuzzy
" - :b lets you autocomplete any open buffer

" Tag Hacks """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! MakeTags !ctags -R .

" NERDtree Hacks """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:netrw_banner=0        " disable annoying banner
let g:netrw_browse_split=4  " open in prior window
let g:netrw_altv=1          " open splits to the right
let g:netrw_liststyle=3     " tree view
let g:netrw_winsize = 20    " 20% of the page
let g:netrw_list_hide=netrw_gitignore#Hide()
let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'
augroup ProjectDrawer
  autocmd!
  autocmd VimEnter * :Vexplore
augroup END

" - :edit a folder to open a file browser
" - <CR>/v/t to open in an h-split/v-split/tab
" - check |netrw-browse-maps| for more mappings

" Performance """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocursorline
set nocursorcolumn
set scrolljump=5
set lazyredraw
set redrawtime=10000
set synmaxcol=180
set re=1
if $TMUX != ''
  set ttimeoutlen=30
elseif &ttimeoutlen > 80 || &ttimeoutlen <= 0
  set ttimeoutlen=80
endif

" ------------------------------------------------------------------------------ 
"  Mapping
" ------------------------------------------------------------------------------ 

map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

if exists('g:vscode')
  let mapleader=","

  nnoremap <silent> ? <Cmd>call VSCodeNotify('workbench.action.findInFiles', { 'query': expand('<cword>')})<CR>
  nnoremap <silent> <C-w>gd <Cmd>call VSCodeNotify('editor.action.revealDefinitionAside')<CR>
  function! s:manageEditorSize(...)
   let count = a:1
   let to = a:2
   for i in range(1, count ? count : 1)
       call VSCodeNotify(to ==# 'increase' ? 'workbench.action.increaseViewSize' : 'workbench.action.decreaseViewSize')
   endfor
  endfunction

  " Sample keybindings. Note these override default keybindings mentioned above.
  nnoremap <C-w>> <Cmd>call <SID>manageEditorSize(v:count, 'increase')<CR>
  xnoremap <C-w>> <Cmd>call <SID>manageEditorSize(v:count, 'increase')<CR>
  nnoremap <C-w>+ <Cmd>call <SID>manageEditorSize(v:count, 'increase')<CR>
  xnoremap <C-w>+ <Cmd>call <SID>manageEditorSize(v:count, 'increase')<CR>
  nnoremap <C-w>< <Cmd>call <SID>manageEditorSize(v:count, 'decrease')<CR>
  xnoremap <C-w>< <Cmd>call <SID>manageEditorSize(v:count, 'decrease')<CR>
  nnoremap <C-w>- <Cmd>call <SID>manageEditorSize(v:count, 'decrease')<CR>
  xnoremap <C-w>- <Cmd>call <SID>manageEditorSize(v:count, 'decrease')<CR>
  xmap gc  <Plug>VSCodeCommentary
  nmap gc  <Plug>VSCodeCommentary
  omap gc  <Plug>VSCodeCommentary
  nmap gcc <Plug>VSCodeCommentaryLine

  nnoremap <leader>ot <Cmd>call VSCodeNotify('workbench.action.toggleSidebarVisibility')<CR>
  nnoremap <leader>tz <Cmd>call VSCodeCall('workbench.action.toggleZenMode')<CR>
else
  let mapleader="\<space>"
  nnoremap <leader>w <c-w>
endif
