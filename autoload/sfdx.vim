let s:bufname = expand("%:p")

" ==== Main =====
function! sfdx#main(name_space, ex_cmd, ...) abort
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
  if a:name_space == 'org'
    call s:org(a:ex_cmd)
    return
  endif

  echo printf("\nExecute the process in the alias: %s",g:alias)

  " hundle commands which isnot excutable without auth
  if a:name_space == 'auth'
    call s:auth(a:ex_cmd)
  elseif a:name_space == 'source'
    call s:source(a:ex_cmd)
  elseif a:name_space == 'apex'
    call s:apex(a:ex_cmd)
  " with some arg
  elseif l:extra_arg != ''
    if a:name_space == 'data'
      call s:data(a:ex_cmd, l:extra_arg)
    endif
  endif
endfunction

function! s:open_term(cmd) abort
    let l:width = winwidth(win_getid())
    let l:height = winheight(win_getid()) * 2.1
    let l:split_height = l:height / 4
    if height > width
      let l:term = printf('bo term ++rows=%s ++shell', l:split_height)
    else
      let l:term = 'vert term ++shell'
    endif

    call execute(printf("%s %s", term, a:cmd))

    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nobuflisted
endfunction

" check login org
function! s:confirm_org()
  let input = input(printf("Select instance to login [p]roduction/[s]andbox/[q]uit: "), "",)
  if input == 'p' || input == 's'
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
      if g:alias == obj.alias
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
  elseif a:ex_cmd == 'list'
    call s:auth_list()
  endif
endfunction

function! s:web_login() abort
  let l:cmd = printf('sfdx force:auth:web:login -r %s -a %s', g:sfdx_login_url, g:alias)
  call s:open_term(cmd)
endfunction

function! s:auth_list() abort
    let l:cmd = 'sfdx auth:list'
    call s:open_term(cmd)
endfunction

" ==== force:org ====
" org#list
function! s:org(ex_cmd) abort
  if a:ex_cmd == 'list'
    call s:org_list()
    return
  endif
  return
endfunction

function! s:org_list() abort
  let l:cmd = 'sfdx force:org:list'
  call s:open_term(cmd)
endfunction

" ==== force:source ====
" check buffer file is sfdx project file?
function! s:is_sfdx_project_file() abort
  let l:extention = expand("%:e")
  let l:patterns = get(g:, 'sfdx_projectfile_patter', [
        \ 'cls',
        \ 'trigger',
        \ 'js',
        \ 'xml',
  \])
  for l:patten in l:patterns
    if l:extention == l:patten
      return 1
    endif
  endfor
    echo 'This is not sfdx project file'
    return 0
endfunction

" deploy current_path file
function! s:source(ex_cmd) abort
  if s:is_sfdx_project_file()
    if a:ex_cmd == 'deploy'
      call s:deploy()
    elseif a:ex_cmd == 'retrieve'
      call s:retrieve()
    endif
  endif
  return
endfunction

function! s:deploy() abort
  let l:cmd = printf('sfdx force:source:deploy --sourcepath %s --targetusername %s', s:bufname, g:alias)
  call s:open_term(cmd)
endfunction

" retrieve current_path file from salesforce
function! s:retrieve() abort
  let l:cmd = printf('sfdx force:source:retrieve --sourcepath %s --targetusername %s', s:bufname, g:alias)
  call s:open_term(cmd)
  redraw
endfunction

" ===== force:apex ====
function! s:apex(ex_cmd) abort
  if !s:is_sfdx_project_file()
    echo printf('You can not create apex file on this directory: %s',s:bufname)
    return
  endif

  if ex_cmd == 'create_apex_file'
    call s:create_apex_file()
  endif
endfunction

" apex#create
function! s:create_apex_file() abort
    let l:class_or_trigger = input(printf('Select file type [c]lass/[t]rigger/[q]uit: '), '',)
    if class_or_trigger == 'c'
      let l:file_type = 'class'
    elseif class_or_trigger == 't'
      let l:file_type = 'trigger'
    else
      return
    endif
    let l:file_name = input(printf('Enter file name '), '',)
    let l:cmd = printf('sfdx force:apex:%s:create -n %s', l:file_type, l:file_name)
    call s:open_term(cmd)
endfunction
" apex#test_run
" - run_apex_test_selected()
" - run_apex_test_all()
" apex#log_list
" apex#log_get

" ==== force:data ====
" data#soql_query
function! s:data(ex_cmd, query)
  if a:ex_cmd == 'execute_soql'
    call s:execute_soql(a:query)
  endif
endfunction

function! s:execute_soql(query) abort
  let l:cmd = printf("sfdx force:data:soql:query -q '%s' -r human --targetusername %s", a:query, g:alias)
  call s:open_term(l:cmd)
endfunction

" data#apex_execute
