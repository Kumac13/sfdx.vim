let s:bufname = expand("%:p")

" ==== Main =====
function! sfdx#main(name_space, ex_cmd, ...) range abort
  let l:extra_arg = get(a:, 1, '')

  " check sfdx command exists
  if !executable('sfdx')
    echo 'sfdx not available.'
    return
  endif

  " set up authentication
  if !s:set_auth()
    return
  endif

  " handle commands which is excutable without auth
  if a:name_space ==# 'org'
    call s:org(a:ex_cmd)
    return
  elseif a:name_space ==# 'pmd'
    call pmd#pmd#pmd(a:ex_cmd)
  endif

  echo printf("\nExecute the process in the alias: %s",g:alias)

  " hundle commands which isnot excutable without auth
  if a:name_space ==# 'auth'
    call s:auth(a:ex_cmd)
  elseif a:name_space ==# 'source'
    call source#controller(a:ex_cmd)
  elseif a:name_space ==# 'apex'
    call apex#apex(a:ex_cmd, a:firstline, a:lastline)
  " with some arg
  elseif l:extra_arg != ''
    if a:name_space ==# 'data'
      call data#data(a:ex_cmd, l:extra_arg)
    endif
  endif
endfunction

" check login org
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
    let l:list = json_decode(system('sfdx auth:list --json'))
    let g:sfdx_auth_list = l:list.result
  endif
  for obj in g:sfdx_auth_list
    if has_key(obj, 'alias')
      if g:alias ==# obj.alias
        let g:sfdx_login_url = obj.instanceUrl
        return 1
      endif
    endif
  endfor
  echo printf("\nThere are no such alias in org: %s", g:alias)
  return 0
endfunction

" ==== force:auth =====
" auth#web_login
function! s:auth(ex_cmd) abort
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

" ==== force:org ====
" org#list
function! s:org(ex_cmd) abort
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

" check buffer file is sfdx project file?
function! sfdx#is_sfdx_project_file() abort
  let l:extention = expand("%:e")
  let l:patterns = get(g:, 'sfdx_projectfile_pattern', [
        \ 'cls',
        \ 'trigger',
        \ 'js',
        \ 'xml',
  \])
  if match(patterns, l:extention) >= 0
    return 1
  endif
  echo 'This is not sfdx project file'
  return 0
endfunction

