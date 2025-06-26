" ==== force:source ====
function! force#source#controller(ex_cmd) abort
  if sfdx#is_sfdx_project_file()
    if a:ex_cmd ==# 'deploy'
      call s:deploy()
    elseif a:ex_cmd ==# 'deploy_force'
      call s:deploy_force()
    elseif a:ex_cmd ==# 'retrieve'
      call s:retrieve()
    elseif a:ex_cmd ==# 'retrieve_force'
      call s:retrieve_force()
    endif
  endif
  return
endfunction

" Deploy current file to salesforce
function! s:deploy() abort
  let l:current_file_path = expand("%:p")
  let l:cmd = printf('sf project deploy start -d %s --target-org %s', l:current_file_path, g:alias)
  call util#open_term(cmd)
endfunction

" Retrieve current_path file from salesforce
function! s:retrieve() abort
  let l:current_file_path = expand("%:p")
  let l:cmd = printf('sf project retrieve start -d %s --target-org %s', l:current_file_path, g:alias)
  call util#open_term(cmd)
  checktime
endfunction

function! s:deploy_force() abort
  let l:current_file_path = expand("%:p")
  let l:cmd = printf('sf project deploy start -d %s --target-org %s --ignore-conflicts', l:current_file_path, g:alias)
  call util#open_term(cmd)
endfunction

function! s:retrieve_force() abort
  let l:current_file_path = expand("%:p")
  let l:cmd = printf('sf project retrieve start -d %s --target-org %s --ignore-conflicts', l:current_file_path, g:alias)
  call util#open_term(cmd)
  checktime
endfunction
