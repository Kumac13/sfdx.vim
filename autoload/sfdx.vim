function! Hoge() abort
  let query = "select id, Name from account limit 5"
  call sfdx#execute_soql(query)
endfunction

let s:is_prod = 1
let s:bufname = expand("%:p")
let g:config_file_path = '~/'
let g:sfdx_sandbox_login_url = 'https://test.salesforce.com'
let g:alias = 'kumac'

" ==== Main =====
function! s:open_term(cmd) abort
    let l:height = winheight(win_getid()) / 4
    let l:term = printf('bo term ++rows=%s ++shell', height)

    call execute(printf("%s %s", term, a:cmd))

    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nobuflisted
endfunction

"
" Config
"
" TODO:
" - current_pathのrootがsalesforceプロジェクトかどうかの確認をしたい
" config#is_sfdx_exist
function! s:is_sfdx_exist() abort
  if executable('sfdx')
    return 1
  else
    echo 'sfdx not available.'
    return 0
  endif
endfunction

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

" ==== force:auth =====
" auth#web_login
function! sfdx#web_login() abort
  let l:cmd = printf('sfdx force:auth:web:login -r %s -a %s', g:sfdx_sandbox_login_url, g:alias)
  call s:open_term(cmd)
endfunction

" ==== force:org ====
" org#list
function! sfdx#org_list() abort
  let l:cmd = 'sfdx force:org:list'
  call s:open_term(cmd)
endfunction

" ==== force:source ====
" deploy current_path file
function! sfdx#deploy() abort
  if s:is_sfdx_project_file() == 1
    let l:cmd = printf('sfdx force:source:deploy --sourcepath %s --targetusername %s', s:bufname, g:alias)
    call s:open_term(cmd)
  else
    echo "You can't deploy this source"
    return
  endif
endfunction

" retrieve current_path file from salesforce
function! sfdx#retrieve() abort
  if s:is_sfdx_project_file() == 1
    let l:cmd = printf('sfdx force:source:retrieve --sourcepath %s --targetusername %s', s:bufname, g:alias)
    call s:open_term(cmd)
    redraw
  else
    echo "You can't retrive this source"
    return
  endif
endfunction

" ===== force:apex ====
" apex#create
" apex#test_run
" apex#log_list
" apex#log_get

" ==== force:data ====
" data#soql_query
function! sfdx#execute_soql(query) abort
  let l:cmd = printf("sfdx force:data:soql:query -q %s -r human --targetusername %s", a:query, g:alias)
  call s:open_term(l:cmd)
endfunction

" data#apex_execute
