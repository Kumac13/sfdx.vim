" ===== force:apex ====
function! force#apex#controller(ex_cmd, nfirstline, nlastline) abort
  if a:ex_cmd ==# 'apex_execute'
    call s:apex_execute(a:nfirstline, a:nlastline)
    return
  elseif a:ex_cmd ==# 'apex_log_list'
    call force#apex#debug#list()
    return
  elseif a:ex_cmd ==# 'apex_log_tail'
    call force#apex#debug#active_debug()
    return
  endif
  if !sfdx#is_sfdx_project_file()
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
    call util#open_term(cmd)
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
  let l:cmd = printf("sf apex run test --tests '%s' --target-org %s -y", l:target_test, g:alias)
  echo printf("Excuting selected test: %s", l:target_test)
  call util#open_term(l:cmd)
endfunction

" Run test class
function! s:run_apex_test_cls() abort
  let l:current_file_name = expand("%:t:r")
  let l:cmd = printf("sf apex run test -n '%s' --target-org %s --result-format human -y", l:current_file_name, g:alias)
  call util#open_term(l:cmd)
endfunction

" Execute apex code block
function! s:apex_execute(nfirstline, nlastline) abort
  let l:outputfile = './tmp.apex'
  let lines = getline(a:nfirstline, a:nlastline)
  call writefile(lines, outputfile)
  call util#open_term(printf("sf apex run --file %s --target-org %s", l:outputfile, g:alias))

  function! s:delete_tmpfile()
    call delete(l:outputfile)
  endfunction

  call timer_start(500, function('s:delete_tmpfile'))
endfunction



