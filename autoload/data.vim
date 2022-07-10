" ==== force:data ====
function! data#data(ex_cmd, query)
  if a:ex_cmd ==# 'execute_soql'
    call s:execute_soql(a:query)
  endif
endfunction

" Get soql query result
function! s:execute_soql(query) abort
  let l:cmd = printf("sfdx force:data:soql:query -q '%s' -r human --targetusername %s", a:query, g:alias)
  call util#open_term(l:cmd)
endfunction

