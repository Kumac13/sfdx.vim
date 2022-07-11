" ==== force:org ====
" org#list
function! org#controller(ex_cmd) abort
  if a:ex_cmd ==# 'list'
    call s:org_list()
    return
  endif
  return
endfunction

function! s:org_list() abort
  let l:cmd = 'sfdx force:org:list'
  call util#open_term(cmd)
endfunction
