
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

  " override defaults with the ones specified in g:dotvim_settings
  for key in keys(s:settings)
    if has_key(g:dotvim_settings, key)
      let s:settings[key] = g:dotvim_settings[key]
    endif
  endfor

" }}}

" setup & neobundle {{{
  let s:cache_dir = '~/.vim/.cache'

  set nocompatible
  if s:is_windows
    set runtimepath+=~/.vim
  endif
  set runtimepath+=~/.vim/bundle/neobundle.vim/
  call neobundle#begin(expand('~/.vim/bundle/'))
  NeoBundleFetch 'Shougo/neobundle.vim'
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
  function! EnsureExists(path) "{{{
    if !isdirectory(expand(a:path))
      call mkdir(expand(a:path))
    endif
  endfunction "}}}
"}}}



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

" fuzzy file/tag searching
NeoBundle 'kien/ctrlp.vim' "{{{

  noremap <leader>t :CtrlP<CR>
  noremap <leader>r :CtrlPTag<cr>
  noremap <leader>br :CtrlPBufTag<cr>

  let g:ctrlp_match_window_reversed = 0
  let g:ctrlp_root_markers = ['.agignore', '.gitignore']
  let g:ctrlp_working_path_mode = 'ra'

  if executable('ag')
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
NeoBundle "rking/ag.vim"

" statusline and tabline
NeoBundle "bling/vim-airline" "{{{
  let g:airline#extensions#tabline#enabled = 1
"}}}

" commenting
NeoBundle "scrooloose/nerdcommenter"

" multiple selection (like sublime text)
NeoBundle "terryma/vim-multiple-cursors"

" auto complete!
if has('lua')
  NeoBundleLazy 'Shougo/neocomplete.vim', {'autoload':{'insert':1}, 'vim_version':'7.3.885'} "{{{
    let g:neocomplete#enable_at_startup=1
    let g:neocomplete#data_directory=s:get_cache_dir('neocomplete')
    let g:neocomplete#sources#syntax#min_keyword_length = 3

    " tab completion
    inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
  " }}}
endif

" allows switching between cpp/h files
NeoBundle 'derekwyatt/vim-fswitch' "{{{
  nnoremap <leader>h :FSHere<cr>
"}}}

" allows closing buffer w/o closing window!
NeoBundle 'rgarver/Kwbd.vim' "{{{
  map <leader>bd <Plug>Kwbd
"}}}

" color schemes
NeoBundle 'wesgibbs/vim-irblack'
NeoBundle 'nanotech/jellybeans.vim'
NeoBundle 'tomasr/molokai'
NeoBundle 'sjl/badwolf'

" vcs plugins
NeoBundle 'matthauck/vimp4python'
" git
NeoBundle "tpope/vim-fugitive"

" key mappings {{{

" re-map to jump to tag definition
map <leader>g <c-]><cr>

 " formatting shortcuts
nmap <leader>f$ :call StripTrailingWhitespace()<CR>
vmap <leader>s :sort<cr>

nnoremap <leader>w :w<cr>

" p4
map <leader>pe :P4Edit<CR>
map <leader>pa :P4Add<CR>
map <leader>pr :P4Revert<CR>
map <leader>pd :P4Diff<CR>
map <leader>pl :P4Filelog<CR>
map <leader>pf :P4Fstat<CR>

" }}}

" autocmd "{{{
" auto strip trailing whitespace on save
autocmd BufWritePre <buffer> call StripTrailingWhitespace()

" change indent settings per file type
autocmd FileType ruby,haml,eruby,yaml,html,javascript,sass,cucumber setl ts=2 sw=2
autocmd FileType python,c,cpp,java setl ts=4 sw=4

"}}}

" finish loading {{{
  if exists('g:dotvim_settings.disabled_plugins')
    for plugin in g:dotvim_settings.disabled_plugins
      exec 'NeoBundleDisable '.plugin
    endfor
  endif

  call neobundle#end()
  filetype plugin indent on
  syntax enable
  if has_key(s:settings, 'colorscheme')
    exec 'colorscheme '.s:settings.colorscheme
  endif

  NeoBundleCheck
"}}}

