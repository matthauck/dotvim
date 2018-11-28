" dotvim settings
"""""""""""""""""

" detect OS
let s:is_windows = has('win32') || has('win64')
let s:is_cygwin = has('win32unix')
let s:is_macvim = has('gui_macvim')

" always use .vim
if s:is_windows
  set runtimepath+=~/.vim
endif
if has('nvim')
  set runtimepath+=~/.vim
endif

" dotvim settings
let s:settings = {}
let s:settings.colorscheme = 'jellybeans'
let s:settings.default_indent = 2
let g:autostrip = 1

" override defaults with the ones specified in g:dotvim_settings
for key in keys(s:settings)
  if has_key(g:dotvim_settings, key)
    let s:settings[key] = g:dotvim_settings[key]
  endif
endfor

let s:cache_dir = '~/.vim/.cache'

function! s:get_cache_dir(suffix)
  return resolve(expand(s:cache_dir . '/' . a:suffix))
endfunction

function! s:ensure_exists(path)
  if !isdirectory(expand(a:path))
    call mkdir(expand(a:path))
  endif
endfunction

function! s:preserve_pos(command)
  " preparation: save last search, and cursor position.
  let _s=@/
  let l = line(".")
  let c = col(".")
  " do the business:
  execute a:command
  " clean up: restore previous search history, and cursor position
  let @/=_s
  call cursor(l, c)
endfunction

" Editor setup
""""""""""""""

set nocompatible
syn on
set nu
set history=10000
set wildmenu
set smartcase
set autoindent
set expandtab
let &tabstop=s:settings.default_indent
let &softtabstop=0 " keep the same as tabstop
let &shiftwidth=s:settings.default_indent
set laststatus=2
set showmatch
set incsearch
set hlsearch
set ffs=unix,dos
set hidden
" note: the final ';' is important. tells it to search upwards for semicolon
set tags=.tags;
filetype plugin indent on
syntax enable
" make searches case-sensitive only if they contain upper-case characters
set ignorecase smartcase

" improve gui on mac
if s:is_macvim
  set antialias
  set guifont=Menlo:h14
endif

" persistent undo
if exists('+undofile')
  set undofile
  let &undodir = s:get_cache_dir('undo')
  call s:ensure_exists(&undodir)
endif

" backups
set backup
let &backupdir = s:get_cache_dir('backup')

" swap files
let &directory = s:get_cache_dir('swap')
set noswapfile

call s:ensure_exists(s:cache_dir)
call s:ensure_exists(&backupdir)
call s:ensure_exists(&directory)


" Plugins
"""""""""

" Install vim-plug

let s:first_install = 0
if !isdirectory(expand('~/.vim/plugged'))
    call mkdir(expand('~/.vim/plugged'))
    let s:first_install = 1
endif
if !filereadable(expand('~/.vim/autoload/plug.vim'))
    echo "Installing vim-plug..."
    exe 'silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
                \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin('~/.vim/plugged')

" languages
Plug 'sheerun/vim-polyglot'

" fuzzy file/tag searching
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
  let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h | %<(20,trunc)%an | %s"'

" yank history
Plug 'vim-scripts/YankRing.vim'

" statusline and tabline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
  let g:airline#extensions#tabline#enabled = 1

" commenting
Plug 'scrooloose/nerdcommenter'

" auto complete!
if has('nvim') || v:version >= 803
  Plug 'neoclide/coc.nvim', {'tag': '*', 'do': { -> coc#util#install()}}
else
  if has('lua')
    Plug 'Shougo/neocomplete.vim'
      let g:neocomplete#enable_at_startup=1
      let g:neocomplete#data_directory=s:get_cache_dir('neocomplete')
      let g:neocomplete#sources#syntax#min_keyword_length = 3
  endif
endif

" allows closing buffer w/o closing window!
Plug 'rgarver/Kwbd.vim'
" color schemes
Plug 'nanotech/jellybeans.vim'
" linting / syntax checking
Plug 'rhysd/vim-clang-format'
" git
Plug 'tpope/vim-fugitive'

" file browsing
Plug 'scrooloose/nerdtree', {'on':['NERDTreeToggle','NERDTreeFind']}
  let NERDTreeShowHidden=1
  let NERDTreeQuitOnOpen=0
  let NERDTreeShowLineNumbers=0
  let NERDTreeChDirMode=0
  let NERDTreeShowBookmarks=1
  let NERDTreeIgnore=['\.git','\.hg', '\.\.$', '\.$', '\~$']
  let NERDTreeBookmarksFile=s:get_cache_dir('NERDTreeBookmarks')
Plug 'Xuyuanp/nerdtree-git-plugin'

" finish vim-plug
call plug#end()

if s:first_install
  exec 'PlugInstall'
endif

" Shortcuts
"""""""""""""""""

" formatting
autocmd FileType c,cpp nnoremap <buffer><Leader>cf :ClangFormat<CR>
autocmd FileType c,cpp vnoremap <buffer><Leader>cf :ClangFormat<CR>
autocmd FileType rust nnoremap <buffer><Leader>cf :RustFmt<CR>
autocmd FileType rust vnoremap <buffer><Leader>cf :RustFmt<CR>

" fuzzy-searching
map <leader>t :GFiles<cr>
map <leader>T :Files<cr>
map <leader>r :Tags<cr>
map <leader>R :BTags<cr>

" open dir tree
nnoremap <leader>o :NERDTreeToggle<CR>
" open dir tree to current file
nnoremap <leader>O :NERDTreeFind<CR>

" misc
nnoremap <leader>P :YRShow<CR>
map <leader>q <Plug>Kwbd

" tab completion
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

" Custom functions
""""""""""""""""""

" :Rg
"  Searching through file contents using `rg` with fzf for fuzzy-searchign
"  through results
"
" --column: Show column number
" --line-number: Show line number
" --no-heading: Do not show file headings in results
" --fixed-strings: Search term as a literal string
" --ignore-case: Case insensitive search
" --no-ignore: Do not respect .gitignore, etc...
" --hidden: Search hidden files and folders
" --follow: Follow symlinks
" --glob: Additional conditions for search (in this case ignore everything in the .git/ folder)
" --color: Search color options
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

function! StripTrailingWhitespace()
  call s:preserve_pos("%s/\\s\\+$//e")
endfunction

function! MaybeStripTrailingWhitespace()
  if g:autostrip
    call StripTrailingWhitespace()
  endif
endfunction()

function! SwitchToTest()
  let dest = ""
  if expand("%") =~ "_test\\.cpp"
    let dest = substitute(expand("%"), "_test\\.cpp$", ".cpp", "")
  elseif expand("%") =~ "\\.cpp$"
    let dest = substitute(expand("%"), "\\.cpp$", "_test.cpp", "")
  elseif expand("%") =~ "\\.h$"
    let dest = substitute(expand("%"), "\\.h$", "_test.cpp", "")
  endif
  if dest != ""
    execute "edit " . dest
  endif
endfunction()

function! SwitchToHeader()
  let dest = ""
  if expand("%") =~ "\\.cpp$"
    let dest = substitute(expand("%"), "\\.cpp$", ".h", "")
  elseif expand("%") =~ "\\.c$"
    let dest = substitute(expand("%"), "\\.c$", ".h", "")
    execute "edit " . dest
  elseif expand("%") =~ "\.h"
    let dest = substitute(expand("%"), "\\.h$", ".cpp", "")
    execute "edit " . dest
  endif
  if dest != ""
    execute "edit " . dest
  endif
endfunction()

" switch to header
nnoremap <leader>h :call SwitchToHeader()<cr>
" switch to test file
nnoremap <leader>H :call SwitchToTest()<cr>

" re-map to jump to tag definition
map <leader>g <c-]><cr>

 " formatting shortcuts
nmap <leader>f$ :call StripTrailingWhitespace()<CR>
vmap <leader>s :sort<cr>

nnoremap <leader>w :w<cr>

" autocmd
"""""""""

autocmd BufRead,BufNewFile *.rs set filetype=rust

" auto strip trailing whitespace on save
autocmd BufWritePre * call MaybeStripTrailingWhitespace()

" change indent settings per file type
autocmd FileType ruby,haml,eruby,yaml,html,javascript,sass,cucumber setl ts=2 sw=2
autocmd FileType python,c,cpp,java setl ts=4 sw=4

" Enable spell check for git commit messages
autocmd FileType gitcommit setlocal spell

" I often typo these...
command Qa :qa
command Wq :wq

" setup colorscheme
if has_key(s:settings, 'colorscheme')
  exec 'colorscheme '.s:settings.colorscheme
endif


" Credit:
" * https://github.com/bling/dotvim
" * https://github.com/sdball/dotfiles/
