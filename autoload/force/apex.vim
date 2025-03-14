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
    elseif a:ex_cmd ==# 'run_apex_test_cls_with_coverage'
      call s:run_apex_test_cls_with_coverage()
    elseif a:ex_cmd ==# 'run_apex_test_selected'
      call s:run_apex_test_selected(a:nfirstline, a:nlastline)
    elseif a:ex_cmd ==# 'run_list_apex_test'
      call s:list_apex_tests()
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
  if !s:is_test_file()
    return
  endif

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

  let l:target_test = expand("%:t:r").".".l:method_name
  let l:cmd = printf("sf apex run test --tests '%s' --target-org %s -y", l:target_test, g:alias)
  echo printf("Excuting selected test: %s", l:target_test)
  call util#open_term(l:cmd)
endfunction

" Run test class
function! s:run_apex_test_cls() abort
  if !s:is_test_file()
    return
  endif

  let l:current_file_name = expand("%:t:r")
  let l:cmd = printf("sf apex run test -n '%s' --target-org %s --result-format human -y", l:current_file_name, g:alias)
  call util#open_term(l:cmd)
endfunction

" Run test class showing test coverage
function! s:run_apex_test_cls_with_coverage() abort
  if !s:is_test_file()
    return
    endif

    let l:current_file_name = expand("%:t:r")
    let l:cmd = printf("sf apex run test -n '%s' --target-org %s --code-coverage --detailed-coverage -r human --synchronous", l:current_file_name, g:alias)
    call util#open_term(l:cmd)
endfunction

" Execute apex code block
let s:temp_apex_file = './tmp.apex'

function! s:apex_execute(nfirstline, nlastline) abort
  let lines = getline(a:nfirstline, a:nlastline)
  call writefile(lines, s:temp_apex_file)
  call util#open_term(printf("sf apex run --file %s --target-org %s", s:temp_apex_file, g:alias))

  call timer_start(1000, 's:delete_temp_file')
endfunction

function! s:delete_temp_file(timer) abort
  if filereadable(s:temp_apex_file)
    call delete(s:temp_apex_file)
  endif
endfunction

function! s:is_test_file() abort
  if expand("%:t:r") !~ "Test"
    echoerr "This is not a Test Class"
    return 0
  endif
  return 1
endfunction

function! s:list_apex_tests() abort
  if !s:is_test_file()
    return
  endif

  " 現在のバッファからテストメソッドを抽出
  let l:lines = getline(1, '$')
  let l:qf_list = []

  for l:idx in range(len(l:lines))
    let l:line_num = l:idx + 1
    let l:line = l:lines[l:idx]

    " @isTest静的メソッドと、testMethodキーワードを持つメソッドを検出
    if l:line =~# '@isTest\s\+static\s\+void\s\+\w\+\s*(' || l:line =~# 'static\s\+testMethod\s\+void\s\+\w\+\s*('
      " メソッド名を抽出
      let l:method_name = matchstr(l:line, '\(static\s\+\(void\|testMethod\s\+void\)\s\+\)\@<=\w\+\ze\s*(')

      if !empty(l:method_name)
        call add(l:qf_list, {
          \ 'filename': expand('%:p'),
          \ 'lnum': l:line_num,
          \ 'text': 'Test Method: ' . l:method_name,
          \ 'method_name': l:method_name
          \ })
      endif
    endif
  endfor

  if empty(l:qf_list)
    echo "No test methods found in this class."
    return
  endif

  " quickfixリストに設定
  call setqflist(l:qf_list)
  copen

  " quickfixリストでEnterキーを押したときのカスタムマッピングを設定
  augroup ApexTestQuickfix
    autocmd!
    autocmd FileType qf nnoremap <buffer> <CR> :call <SID>run_selected_test()<CR>
  augroup END
endfunction

" quickfixリストから選択されたテストを実行する関数
function! s:run_selected_test() abort
  let l:qf_item = getqflist()[line('.') - 1]
  let l:method_name = l:qf_item.method_name
  let l:class_name = fnamemodify(l:qf_item.filename, ':t:r')

  let l:target_test = l:class_name . '.' . l:method_name
  let l:cmd = printf("sf apex run test --tests '%s' --target-org %s -y", l:target_test, g:alias)

  echo printf("Executing selected test: %s", l:target_test)
  call util#open_term(l:cmd)

  " quickfixウィンドウを閉じる（オプション）
  " cclose
endfunction

