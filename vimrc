
" borrowed heavily from https://github.com/bling/dotvim

" detect OS {{{
  let s:is_windows = has('win32') || has('win64')
  let s:is_cygwin = has('win32unix')
  let s:is_macvim = has('gui_macvim')
"}}}
"

" dotvim settings {{{
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

" }}}

" functions {{{
  function! s:get_cache_dir(suffix) "{{{
    return resolve(expand(s:cache_dir . '/' . a:suffix))
  endfunction "}}}
  function! Source(begin, end) "{{{
    let lines = getline(a:begin, a:end)
    for line in lines
      execute line
    endfor
  endfunction "}}}
  function! Preserve(command) "{{{
    " preparation: save last search, and cursor position.
    let _s=@/
    let l = line(".")
    let c = col(".")
    " do the business:
    execute a:command
    " clean up: restore previous search history, and cursor position
    let @/=_s
    call cursor(l, c)
  endfunction "}}}
  function! StripTrailingWhitespace() "{{{
    call Preserve("%s/\\s\\+$//e")
  endfunction "}}}
  function! MaybeStripTrailingWhitespace()
    if g:autostrip
      call StripTrailingWhitespace()
    endif
  endfunction()
  function! EnsureExists(path) "{{{
    if !isdirectory(expand(a:path))
      call mkdir(expand(a:path))
    endif
  endfunction "}}}

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

"}}}


" setup & vim-plugin {{{

  set nocompatible
  if s:is_windows
    set runtimepath+=~/.vim
  endif

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
" }}}




syn on
set nu
set history=1000
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

" set statusline=%<%f\ (%{&ft})\ %-4(%m%)%=%-19(%3l,%02c%03V%)

" note: the final ';' is important. tells it to search upwards for semicolon
set tags=.tags;

" improve gui on mac
if s:is_macvim
  set antialias
  set guifont=Menlo:h14
endif

" vim file/folder management {{{
    " persistent undo
    if exists('+undofile')
      set undofile
      let &undodir = s:get_cache_dir('undo')
      call EnsureExists(&undodir)
    endif

    " backups
    set backup
    let &backupdir = s:get_cache_dir('backup')

    " swap files
    let &directory = s:get_cache_dir('swap')
    set noswapfile

    call EnsureExists(s:cache_dir)
    call EnsureExists(&backupdir)
    call EnsureExists(&directory)
  "}}}

"}}}


" plugins {{{

" add vimproc first for other things that depend on it
Plug 'Shougo/vimproc.vim', { 'do' : 'make' }

" fuzzy file/tag searching
Plug 'ctrlpvim/ctrlp.vim' "{{{

  noremap <leader>t :CtrlP<CR>
  noremap <leader>r :CtrlPTag<cr>
  noremap <leader>R :CtrlPBufTag<cr>

  let g:ctrlp_match_window_reversed = 0
  let g:ctrlp_root_markers = ['.agignore', '.gitignore']
  " just use the directory vim is started in
  let g:ctrlp_working_path_mode = ''

  let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'

  if isdirectory('.git')
    let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
  elseif executable('ag')
    let g:ctrlp_user_command = 'ag %s -i --nocolor --nogroup --hidden
          \ --ignore .git
          \ --ignore .svn
          \ --ignore .hg
          \ --ignore .DS_Store
          \ --ignore "**/*.pyc"
          \ -g ""'
  endif
"}}}

" searching
Plug 'jremmen/vim-ripgrep'

" yank history
Plug 'vim-scripts/YankRing.vim' "{{{
  nnoremap <leader>P :YRShow<CR>
"}}}

" statusline and tabline
Plug 'vim-airline/vim-airline' "{{{
  let g:airline#extensions#tabline#enabled = 1
  let g:airline#extensions#syntastic#enabled = 1
"}}}
Plug 'vim-airline/vim-airline-themes'

" commenting
Plug 'scrooloose/nerdcommenter'

" auto complete!
if has('lua')
  Plug 'Shougo/neocomplete.vim', {'autoload':{'insert':1}, 'vim_version':'7.3.885'} "{{{
    let g:neocomplete#enable_at_startup=1
    let g:neocomplete#data_directory=s:get_cache_dir('neocomplete')
    let g:neocomplete#sources#syntax#min_keyword_length = 3

    " tab completion
    inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
  " }}}
endif

" allows closing buffer w/o closing window!
Plug 'rgarver/Kwbd.vim' "{{{
  map <leader>q <Plug>Kwbd
"}}}

" color schemes
Plug 'wesgibbs/vim-irblack'
Plug 'nanotech/jellybeans.vim'
Plug 'tomasr/molokai'
Plug 'sjl/badwolf'

" languages
Plug 'rust-lang/rust.vim' "{{{
  autocmd FileType rust nnoremap <buffer><Leader>cf :RustFmt<CR>
  autocmd FileType rust vnoremap <buffer><Leader>cf :RustFmt<CR>
"}}}
Plug 'cespare/vim-toml'

Plug 'genoma/vim-less'
Plug 'leafgarland/typescript-vim'
Plug 'fatih/vim-go'

" typescript tooling
Plug 'Quramy/tsuquyomi' "{{{
  " match sublime text mappings
  map <c-t><c-d> :TsuquyomiDefinition<CR>
  map <c-t><c-r> :TsuquyomiReferences<CR>
"}}}

" linting / syntax checking
Plug 'rhysd/vim-clang-format' "{{{
  autocmd FileType c,cpp nnoremap <buffer><Leader>cf :ClangFormat<CR>
  autocmd FileType c,cpp vnoremap <buffer><Leader>cf :ClangFormat<CR>
  " Toggle auto formatting:
  " autocmd FileType c,cpp ClangFormatAutoEnable
"}}}

Plug 'scrooloose/syntastic'
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0
let g:syntastic_typescript_checkers = ['tslint']
let g:syntastic_mode_map = {
      \  "mode": "active",
      \  "active_filetypes": [ "typescript" ],
      \  "passive_filetypes": []
      \ }

map <leader>l :SyntasticCheck<CR>

Plug 'tpope/vim-fugitive'

" file browsing
Plug 'scrooloose/nerdtree', {'on':['NERDTreeToggle','NERDTreeFind']} "{{{
  let NERDTreeShowHidden=1
  let NERDTreeQuitOnOpen=0
  let NERDTreeShowLineNumbers=0
  let NERDTreeChDirMode=0
  let NERDTreeShowBookmarks=1
  let NERDTreeIgnore=['\.git','\.hg', '\.\.$', '\.$', '\~$']
  let NERDTreeBookmarksFile=s:get_cache_dir('NERDTreeBookmarks')

  " open dir tree
  nnoremap <leader>o :NERDTreeToggle<CR>
  " open dir tree to current file
  nnoremap <leader>O :NERDTreeFind<CR>
"}}}
Plug 'Xuyuanp/nerdtree-git-plugin'

" misc. key mappings {{{

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
" }}}

" autocmd "{{{

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

"}}}

" finish loading {{{
  if exists('g:dotvim_settings.disabled_plugins')
    for plugin in g:dotvim_settings.disabled_plugins
      "FIXME exec 'NeoBundleDisable '.plugin
    endfor
  endif

  call plug#end()

  if s:first_install
    exec 'PlugInstall'
  endif

  filetype plugin indent on
  syntax enable
  if has_key(s:settings, 'colorscheme')
    exec 'colorscheme '.s:settings.colorscheme
  endif

"}}}

