" ==== force:auth =====
" auth#web_login
function! auth#controller(ex_cmd) abort
  if a:ex_cmd == 'login'
    call s:web_login()
  elseif a:ex_cmd ==# 'list'
    call s:auth_list()
  endif
endfunction

function! s:web_login() abort
  let l:cmd = printf('sfdx force:auth:web:login -r %s -a %s', g:sfdx_login_url, g:alias)
  call util#open_term(cmd)
endfunction

function! s:auth_list() abort
    let l:cmd = 'sfdx auth:list'
    call util#open_term(cmd)
endfunction
