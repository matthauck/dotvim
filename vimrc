
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
  function! EnsureExists(path) "{{{
    if !isdirectory(expand(a:path))
      call mkdir(expand(a:path))
    endif
  endfunction "}}}
"}}}


" setup & dein {{{

  set nocompatible
  if s:is_windows
    set runtimepath+=~/.vim
  endif

  if !isdirectory(expand('~/.vim/dein/dein.vim'))
      call mkdir(expand('~/.vim/dein'))
      echo "Cloning https://github.com/Shougo/dein.vim..."
      exe 'silent !git -C ~/.vim/dein clone --quiet https://github.com/Shougo/dein.vim'
  endif

  set runtimepath+=~/.vim/dein/dein.vim

  call dein#begin(expand('~/.vim/dein/'))
  call dein#add(expand('~/.vim/dein/dein.vim'))
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
call dein#add('Shougo/vimproc.vim', { 'build' : 'make' })

" fuzzy file/tag searching
call dein#add('kien/ctrlp.vim') "{{{

  noremap <leader>t :CtrlP<CR>
  noremap <leader>r :CtrlPTag<cr>
  noremap <leader>R :CtrlPBufTag<cr>

  let g:ctrlp_match_window_reversed = 0
  let g:ctrlp_root_markers = ['.agignore', '.gitignore']
  " just use the directory vim is started in
  let g:ctrlp_working_path_mode = ''

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
call dein#add('rking/ag.vim')

" yank history
call dein#add('vim-scripts/YankRing.vim') "{{{
  nnoremap <leader>P :YRShow<CR>
"}}}

" statusline and tabline
call dein#add('vim-airline/vim-airline') "{{{
  let g:airline#extensions#tabline#enabled = 1
  let g:airline#extensions#syntastic#enabled = 1
"}}}
call dein#add('vim-airline/vim-airline-themes')

" commenting
call dein#add('scrooloose/nerdcommenter')

" auto complete!
if has('lua')
  call dein#add('Shougo/neocomplete.vim', {'autoload':{'insert':1}, 'vim_version':'7.3.885'}) "{{{
    let g:neocomplete#enable_at_startup=1
    let g:neocomplete#data_directory=s:get_cache_dir('neocomplete')
    let g:neocomplete#sources#syntax#min_keyword_length = 3

    " tab completion
    inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
  " }}}
endif

" allows switching between cpp/h files
call dein#add('derekwyatt/vim-fswitch') "{{{
  nnoremap <leader>h :FSHere<cr>
"}}}

" allows closing buffer w/o closing window!
call dein#add('rgarver/Kwbd.vim') "{{{
  map <leader>q <Plug>Kwbd
"}}}

" color schemes
call dein#add('wesgibbs/vim-irblack')
call dein#add('nanotech/jellybeans.vim')
call dein#add('tomasr/molokai')
call dein#add('sjl/badwolf')

" languages
call dein#add('rust-lang/rust.vim')
call dein#add('genoma/vim-less')
call dein#add('leafgarland/typescript-vim')
call dein#add('fatih/vim-go')

" typescript tooling
call dein#add('Quramy/tsuquyomi') "{{{
  " match sublime text mappings
  map <c-t><c-d> :TsuquyomiDefinition<CR>
  map <c-t><c-r> :TsuquyomiReferences<CR>
"}}}

" linting / syntax checking
call dein#add('scrooloose/syntastic')
"let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_typescript_checkers = ['tslint']
let g:syntastic_mode_map = {
      \  "mode": "active",
      \  "active_filetypes": [ "typescript" ],
      \  "passive_filetypes": []
      \ }

map <leader>l :SyntasticCheck<CR>

call dein#add('tpope/vim-fugitive')

" file browsing
call dein#add('scrooloose/nerdtree', {'autoload':{'commands':['NERDTreeToggle','NERDTreeFind']}}) "{{{
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
call dein#add('Xuyuanp/nerdtree-git-plugin')

" misc. key mappings {{{
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
autocmd BufWritePre * call StripTrailingWhitespace()

" change indent settings per file type
autocmd FileType ruby,haml,eruby,yaml,html,javascript,sass,cucumber setl ts=2 sw=2
autocmd FileType python,c,cpp,java setl ts=4 sw=4

"}}}

" finish loading {{{
  if exists('g:dotvim_settings.disabled_plugins')
    for plugin in g:dotvim_settings.disabled_plugins
      "FIXME exec 'NeoBundleDisable '.plugin
    endfor
  endif

  call dein#end()

  if dein#check_install()
    call dein#install()
  endif

  filetype plugin indent on
  syntax enable
  if has_key(s:settings, 'colorscheme')
    exec 'colorscheme '.s:settings.colorscheme
  endif

"}}}

