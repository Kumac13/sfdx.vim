let s:bufname = expand("%:p")
let g:sfdx_login_url = 'https://login.salesforce.com'

" ==== Main =====
function! sfdx#main(name_space, ex_cmd) abort
  if !executable('sfdx')
    echo 'sfdx not available.'
    return
  endif

  if a:name_space == 'org'
    call s:org(a:ex_cmd)
    return
  endif

  if !exists('g:alias')
    call s:confirm_org()
  endif
  echo printf('Execute the process in the alias: %s',g:alias)

  if a:name_space == 'auth'
    call s:auth(a:ex_cmd)
  elseif a:name_space == 'source'
    call s:source(a:ex_cmd)
  endif
endfunction

function! s:open_term(cmd) abort
    let l:height = winheight(win_getid()) / 4
    let l:term = printf('bo term ++rows=%s ++shell', height)

    call execute(printf("%s %s", term, a:cmd))

    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nobuflisted
endfunction

" check login org
function! s:confirm_org()
  let input = input(printf('Select instance to login [p]roduction/[s]andbox/[q]uit: '), '',)
  if input == 'q'
    echo 'q'
    return 0
  elseif input == 's'
    let g:sfdx_login_url = 'https://test.salesforce.com'
  endif
  let g:alias = input(printf('Enter an org alias or user default alias: '), '')
  return 1
endfunction


" ==== force:auth =====
" auth#web_login
function! s:auth(ex_cmd) abort
  if a:ex_cmd == 'login'
    call s:web_login()
  endif
endfunction

function! s:web_login() abort
  let l:cmd = printf('sfdx force:auth:web:login -r %s -a %s', g:sfdx_login_url, g:alias)
  call s:open_term(cmd)
endfunction

function! s:auth_list() abort
  if !exists('g:auth_list')
    let l:cmd = 'sfdx auth:list --json'
    let g:auth_list = json_decode(system(l:cmd)).result
  endif
  for obj in g:auth_list
    if has_key(obj, 'alias')
      " let g:alias = obj.alias
      echo obj.isSandbox
    else
      call s:confirm_org()
      call s:web_login()
    endif
  endfor
endfunction

function! Hoge() abort
  call s:auth_list()
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
" apex#create
function! sfdx#create_apex_file() abort
  if s:is_sfdx_project_file() == 1
    let l:class_or_trigger = input(printf('Select file type [c]lass/[t]rigger/[q]uit: '), '',)
    if class_or_trigger == 'c'
      let l:file_type = 'class'
    elseif class_or_trigger == 't'
      let l:file_type = 'trigger'
    else
      return
    endif
    let l:file_name = input(printf('Enter file name '), '',)
    echo l:file_name
    let l:cmd = printf('sfdx force:apex:%s:create -n %s', l:file_type, l:file_name)
  else
    echo printf('You can not create apex file on this directory: %s',s:bufname)
    return
  endif
endfunction
" apex#test_run
" - run_apex_test_selected()
" - run_apex_test_all()
" apex#log_list
" apex#log_get

" ==== force:data ====
" data#soql_query
function! s:data(ex_cmd)
endfunction

function! sfdx#execute_soql(query) abort
  let l:cmd = printf("sfdx force:data:soql:query -q %s -r human --targetusername %s", a:query, g:alias)
  call s:open_term(l:cmd)
endfunction

" data#apex_execute
"
"
