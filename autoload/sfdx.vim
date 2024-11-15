let s:bufname = expand("%:p")

" ==== Main =====
function! sfdx#main(name_space, ex_cmd, ...) range abort
  let l:extra_arg = get(a:, 1, '')

  " check sf command exists
  if !executable('sf')
    echo 'sf command not available.'
    return
  endif

  " use cmd without alias
  if a:name_space ==# 'pmd'
    call pmd#controller(a:ex_cmd)
    return
  elseif a:name_space ==# 'org'
    call org#controller(a:ex_cmd)
    return
  endif

  " set up authentication
  if !s:set_auth()
    return
  endif

  echo printf("\nExecute the process in the alias: %s",g:alias)

  " hundle commands which isnot excutable without auth
  try
    if a:name_space ==# 'auth'
      call auth#controller(a:ex_cmd)
    elseif a:name_space ==# 'source'
      call force#source#controller(a:ex_cmd)
    elseif a:name_space ==# 'apex'
      call force#apex#controller(a:ex_cmd, a:firstline, a:lastline)
    elseif a:name_space ==# 'sobject'
      call sobject#controller(a:ex_cmd, l:extra_arg)
    " with some arg
    elseif l:extra_arg != ''
      if a:name_space ==# 'data'
        call data#controller(a:ex_cmd, l:extra_arg)
      endif
    endif
  catch /.*/
    let l:error_msg = v:exception
    throw l:error_msg
  endtry
endfunction

function! s:confirm_org()
  let input = input(printf("Select instance to login [p]roduction/[s]andbox/[q]uit: "), "",)
  if input ==# 'p' || input ==# 's'
    let g:alias = input(printf("\nEnter an org alias or user default alias: "), "")
    return 1
  else
    return 0
  endif
endfunction

function! s:set_auth() abort
  if !exists('g:alias')
    if !s:confirm_org()
      return 0
    endif
  endif

  if !exists('g:sfdx_auth_list')
    let l:parsed_output = util#execute_cmd('sf auth list --json')
    let l:list = json_decode(l:parsed_output)
    let g:sfdx_auth_list = l:list.result
  endif

  let g:alias_list = []
  for obj in g:sfdx_auth_list
    if has_key(obj, 'alias')
      let l:instance_url = obj.instanceUrl
      let l:aliases = split(obj.alias, ',')
      for l:alias in l:aliases
        call add(g:alias_list, {'alias': l:alias, 'instanceUrl': l:instance_url})
      endfor
    else
      continue
    endif
  endfor

  let l:found_alias = filter(g:alias_list, {k, v -> v.alias ==# g:alias})
  if len(l:found_alias) > 0
    let g:sfdx_login_url = l:found_alias[0].instanceUrl
    return 1
  else
    echo printf("\nThere are no such alias in org: %s", g:alias)
    return 0
  endif
endfunction


" check buffer file is sfdx project file?
function! sfdx#is_sfdx_project_file() abort
  let l:extention = expand("%:e")
  let l:patterns = get(g:, 'sfdx_projectfile_pattern', [
        \ 'cls',
        \ 'trigger',
        \ 'js',
        \ 'css',
        \ 'html',
        \ 'xml',
        \])

  if match(patterns, l:extention) >= 0
    return 1
  endif
  echo 'This is not sfdx project file'
  return 0
endfunction
