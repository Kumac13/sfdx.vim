function! org#controller(ex_cmd) abort
  if a:ex_cmd ==# 'list'
    call s:list()
  elseif a:ex_cmd ==# 'open'
    call s:open()
  endif
endfunction

function! s:list() abort
  call util#open_term('sf org list')
endfunction

function! s:open() abort
  let l:cmd = printf('sf org open -o %s', g:alias)
  execute system(l:cmd)
endfunction
