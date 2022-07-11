" ==== force:source ====
"
function! source#controller(ex_cmd) abort
  if s:is_sfdx_project_file()
    if a:ex_cmd ==# 'deploy'
      call s:deploy()
    elseif a:ex_cmd ==# 'retrieve'
      call s:retrieve()
    endif
  endif
  return
endfunction

" Deploy current file to salesforce
function! s:deploy() abort
  let l:current_file_path = expand("%:p")
  let l:cmd = printf('sfdx force:source:deploy --sourcepath %s --targetusername %s', l:current_file_path, g:alias)
  call util#open_term(cmd)
endfunction

" Retrieve current_path file from salesforce
function! s:retrieve() abort
  let l:current_file_path = expand("%:p")
  let l:cmd = printf('sfdx force:source:retrieve --sourcepath %s --targetusername %s', l:current_file_path, g:alias)
  call util#open_term(cmd)
  redraw
endfunction
