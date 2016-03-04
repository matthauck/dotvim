let s:loaded_session = ''

function! s:OnLoadedSession()
  let s:loaded_session = v:this_session
  " auto-save loaded sessions on exit
  au VimLeave * :call sessions#SaveSession()
endfunction

au SessionLoadPost * :call s:OnLoadedSession()

function! sessions#SaveSession()
  if s:loaded_session == ''
    echo "No session loaded"
  else
    echo "Saving " . s:loaded_session
    exe "mksession! " . s:loaded_session
  endif
endfunction

function! sessions#NewSession(name)
  exe "mksession! " . a:name
  call s:OnLoadedSession()
endfunction

command! -nargs=1 NewSession call s:NewSession(<f-args>)
