" ==== force:data ====
function! data#controller(ex_cmd, query)
  if a:ex_cmd ==# 'execute_soql'
    call s:execute_soql(a:query)
  endif
endfunction

" Get soql query result
function! s:execute_soql(query) abort
  let l:cmd = printf("sfdx data query --query '%s' -r human --target-org %s", a:query, g:alias)
  call util#open_term(l:cmd)
endfunction

