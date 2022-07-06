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
    call s:pmd(a:ex_cmd)
  endif

  echo printf("\nExecute the process in the alias: %s",g:alias)

  " hundle commands which isnot excutable without auth
  if a:name_space ==# 'auth'
    call s:auth(a:ex_cmd)
  elseif a:name_space ==# 'source'
    call s:source(a:ex_cmd)
  elseif a:name_space ==# 'apex'
    call s:apex(a:ex_cmd, a:firstline, a:lastline)
  " with some arg
  elseif l:extra_arg != ''
    if a:name_space ==# 'data'
      call s:data(a:ex_cmd, l:extra_arg)
    endif
  endif
endfunction

function! s:open_term(cmd) abort
    let l:width = winwidth(win_getid())
    let l:height = winheight(win_getid()) * 2.1
    let l:split_height = l:height / 8
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
  call s:open_term(cmd)
endfunction

function! s:auth_list() abort
    let l:cmd = 'sfdx auth:list'
    call s:open_term(cmd)
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
  call s:open_term(cmd)
endfunction

" ==== force:source ====
function! s:source(ex_cmd) abort
  if s:is_sfdx_project_file()
    if a:ex_cmd ==# 'deploy'
      call s:deploy()
    elseif a:ex_cmd ==# 'retrieve'
      call s:retrieve()
    endif
  endif
  return
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
    if l:extention ==# l:patten
      return 1
    endif
  endfor
    echo 'This is not sfdx project file'
    return 0
endfunction

" Deploy current file to salesforce
function! s:deploy() abort
  let l:current_file_path = expand("%:p")
  let l:cmd = printf('sfdx force:source:deploy --sourcepath %s --targetusername %s', l:current_file_path, g:alias)
  call s:open_term(cmd)
endfunction

" Retrieve current_path file from salesforce
function! s:retrieve() abort
  let l:current_file_path = expand("%:p")
  let l:cmd = printf('sfdx force:source:retrieve --sourcepath %s --targetusername %s', l:current_file_path, g:alias)
  call s:open_term(cmd)
  redraw
endfunction

" ===== force:apex ====
function! s:apex(ex_cmd, nfirstline, nlastline) abort
  if a:ex_cmd ==# 'apex_execute'
    call s:apex_execute(a:nfirstline, a:nlastline)
    return
  elseif a:ex_cmd ==# 'apex_log_list'
    call s:apex_log_list()
    return
  elseif a:ex_cmd ==# 'apex_log_tail'
    call s:apex_log_tail()
    return
  endif
  if !s:is_sfdx_project_file()
    echo printf('You can not create apex file on this directory: %s',s:bufname)
    return
  else
    if a:ex_cmd ==# 'create_apex_file'
      call s:create_apex_file()
    elseif a:ex_cmd ==# 'run_apex_test_cls'
      call s:run_apex_test_cls()
    elseif a:ex_cmd ==# 'run_apex_test_selected'
      call s:run_apex_test_selected(a:nfirstline, a:nlastline)
    endif
  endif
endfunction

" Create apex file
function! s:create_apex_file() abort
    let l:class_or_trigger = input(printf('Select file type [c]lass/[t]rigger/[q]uit: '), '',)
    if class_or_trigger ==# 'c'
      let l:file_type = 'class'
    elseif class_or_trigger ==# 't'
      let l:file_type = 'trigger'
    else
      return
    endif
    let l:file_name = input(printf('Enter file name '), '',)
    let l:cmd = printf('sfdx force:apex:%s:create -n %s', l:file_type, l:file_name)
    call s:open_term(cmd)
endfunction

" Run selected test method
function! s:run_apex_test_selected(nfirstline, nlastline) abort
  let lines = getline(a:nfirstline, a:nlastline)
  let list = split(lines[0], ' ')
  let l:method_name = ''

  for item in list
    let int =  match(item, '()')
    if int > 0
      let l:method_name = matchstr(item, '.*\ze(')
    endif
  endfor
  if l:method_name ==# ''
    echo "No method name"
    return
  endif

  if expand("%:t:r") !~ "Test"
    echo "This is not Test Class"
    return
  endif
  let l:target_test = expand("%:t:r").".".l:method_name
  let l:cmd = printf("sfdx force:apex:test:run -t '%s' -u %s", l:target_test, g:alias)
  echo printf("Excuting selected test: %s", l:target_test)
  let l:test_run_result = system(cmd)
  let l:cmd = matchstr(test_run_result, '"\zs.*\ze"')
  call s:open_term(l:cmd)
endfunction

" Run test class
function! s:run_apex_test_cls() abort
  let l:current_file_name = expand("%:t:r")
  let l:cmd = printf("sfdx force:apex:test:run -n '%s' -u %s -r human", l:current_file_name, g:alias)
  call s:open_term(l:cmd)
endfunction

" Execute apex code block
function! s:apex_execute(nfirstline, nlastline) abort
  let l:outputfile = "./tmp.apex"
  if !filereadable(outputfile)
    execute "redir > ".outputfile
  endif
  let lines = getline(a:nfirstline, a:nlastline)
  call writefile(lines, outputfile)
  call s:open_term(printf("sfdx force:apex:execute -f tmp.apex -u %s", g:alias))
endfunction


" Get Debug log list
function! s:apex_log_list()
  let l:cmd = printf("sfdx force:apex:log:list -u %s", g:alias)
  call s:open_term(l:cmd)
endfunction
" apex#log_get

" Activates debug logging
function! s:apex_log_tail()
  let l:cmd = printf("sfdx force:apex:log:tail -u %s", g:alias)
  call s:open_term(l:cmd)
endfunction

" ==== force:data ====
function! s:data(ex_cmd, query)
  if a:ex_cmd ==# 'execute_soql'
    call s:execute_soql(a:query)
  endif
endfunction

" Get soql query result
function! s:execute_soql(query) abort
  let l:cmd = printf("sfdx force:data:soql:query -q '%s' -r human --targetusername %s", a:query, g:alias)
  call s:open_term(l:cmd)
endfunction

" Use Apex PMD
" - Need to download pmd
function! s:pmd(ex_cmd)
  if a:ex_cmd ==# 'pmd_current_file'
    call s:pmd_current_file()
  endif
endfunction

function! s:pmd_current_file()
  echo "\nExecuting Apex Pmd..."
  let pmd = NewPmd()
  call pmd.perform()
endfunction

let g:pmd = {'run_path': $PMD_PATH, 'target_path':'', 'result':''}

function! pmd.command() dict abort
  return join([self.run_path, 'pmd', '-d', self.target_path, '-R ./rulesets/apex_ruleset.xml -f csv'], ' ' )
endfunction

function! pmd.perform() dict abort
  let self.result = split(system(self.command()), '\n')
  let l:regex = 'net\.sourceforge\.pmd\.PMD\|parseRuleReferenceNode\|WARNING'

  let filterd = filter(self.result, {-> !util#is_regex_match(v:val, l:regex)})

  let parsed = map(copy(filterd), {-> NewPmdResult(v:val).display()})

  call buffer#open_list(parsed)

endfunction

function! NewPmd() abort
  let self = copy(g:pmd)
  let self.target_path = expand('%:p')
  return self
endfunction

let g:pmd_result = {'File': '', 'Column':'', 'Rule': '', 'Description':''}

function! pmd_result.display() dict abort
  return printf('%s | %s | %s | %s', self.File, self.Column, self.Rule, self.Description)
endfunction

function! NewPmdResult(result_row) abort
  let self = copy(g:pmd_result)
  let split_item = split(a:result_row, ',')
  echo split_item
  let self.File = expand('%:p')
  let self.Column = trim(split_item[4], '"', 0)
  let self.Rule = trim(split_item[7], '"', 0)
  let self.Description = trim(split_item[5], '"', 0)
  return self
endfunction



