" ===== force:apex ====
function! force#apex#controller(ex_cmd, nfirstline, nlastline) abort
  if a:ex_cmd ==# 'apex_execute'
    call s:apex_execute(a:nfirstline, a:nlastline)
    return
  elseif a:ex_cmd ==# 'apex_execute_markdown_block'
    call force#apex#execute_markdown_apex_block()
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
function! s:apex_execute(nfirstline, nlastline) abort
  let lines = getline(a:nfirstline, a:nlastline)
  let s:temp_apex_file = getcwd() . '/tmp.apex'
  call writefile(lines, s:temp_apex_file)
  call util#open_term(printf("sf apex run --file %s --target-org %s", s:temp_apex_file, g:alias))

  call timer_start(1000, 's:delete_temp_file')
endfunction

" Markdownファイル内のApexコードブロックを実行する
function! force#apex#execute_markdown_apex_block() abort
  " 現在の行番号を取得
  let l:current_line = line('.')
  let l:start_line = 0
  let l:end_line = 0

  " カーソルより上の行を検索して```apexを見つける
  let l:line_num = l:current_line
  while l:line_num > 0
    let l:line = getline(l:line_num)
    if l:line =~# '^\s*```\s*apex'
      let l:start_line = l:line_num + 1
      break
    endif
    let l:line_num -= 1
  endwhile

  " カーソルより下の行を検索して```を見つける
  let l:line_num = l:current_line
  let l:last_line = line('$')
  while l:line_num <= l:last_line
    let l:line = getline(l:line_num)
    if l:line =~# '^\s*```\s*$' && l:start_line > 0
      let l:end_line = l:line_num - 1
      break
    endif
    let l:line_num += 1
  endwhile

  " 有効なブロックが見つかった場合は実行
  if l:start_line > 0 && l:end_line > 0 && l:start_line <= l:end_line
    call s:apex_execute(l:start_line, l:end_line)
    return 1
  endif

  echo "カーソルがApexコードブロック内にありません"
  return 0
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
  let l:test_methods = []
  let l:buffer_name = expand('%:t:r')
  let l:in_method = 0

  " タグのパターン（@IsTestや@TestSetupなど）
  let l:istest_pattern = '@IsTest\|@TestSetup\|@Test'

  for l:idx in range(len(l:lines))
    let l:line_num = l:idx + 1
    let l:line = l:lines[l:idx]
    let l:trimmed_line = substitute(l:line, '^\s*', '', '')

    " @IsTest、@TestSetupなどのアノテーションを検出
    if l:trimmed_line =~? l:istest_pattern
      let l:in_method = 1
      continue
    endif

    " アノテーションの後にprivate/public static voidメソッド定義を検出
    if l:in_method && l:trimmed_line =~? '^\(private\|public\|static\|void\|testMethod\)\s\+'
      if l:trimmed_line =~? '\<void\s\+\w\+\s*('
        " メソッド名を抽出
        let l:method_name = matchstr(l:trimmed_line, '\<void\s\+\zs\w\+\ze\s*(')
        if !empty(l:method_name)
          call add(l:test_methods, l:method_name)
        endif
      endif
      let l:in_method = 0
    elseif l:trimmed_line =~? '^\(private\|public\|static\)\s\+testMethod\s\+void\s\+\w\+\s*('
      " testMethod キーワードを直接使用している場合
      let l:method_name = matchstr(l:trimmed_line, 'testMethod\s\+void\s\+\zs\w\+\ze\s*(')
      if !empty(l:method_name)
        call add(l:test_methods, l:method_name)
      endif
    endif
  endfor

  if empty(l:test_methods)
    echo "No test methods found in this class."
    return
  endif

  " リストに表示するための整形
  let l:display_list = []
  for l:idx in range(len(l:test_methods))
    call add(l:display_list, printf("%d. %s", l:idx + 1, l:test_methods[l:idx]))
  endfor

  " グローバル変数にテストメソッド情報を保存（選択用）
  let g:apex_test_methods = l:test_methods
  let g:apex_test_class = l:buffer_name

  " util#listを使ってリストを表示
  call util#list(
    \ 'apex-test-methods//',
    \ l:display_list,
    \ 'force#apex#run_selected_test',
    \ 'execute the selected test method'
  \)
endfunction

" グローバル関数として定義（リストからアクセスできるようにするため）
function! force#apex#run_selected_test(selected_line) abort
  " エラーハンドリングを強化
  if !exists('g:apex_test_methods') || !exists('g:apex_test_class')
    echo "Test method data is not available. Please run the list command again."
    return
  endif

  " 選択された行から番号を抽出（例: "1. testMethodName" -> 1）
  let l:selected_index = str2nr(matchstr(a:selected_line, '^\d\+')) - 1

  if l:selected_index < 0 || l:selected_index >= len(g:apex_test_methods)
    echo "Invalid selection"
    return
  endif

  let l:method_name = g:apex_test_methods[l:selected_index]
  let l:class_name = g:apex_test_class

  let l:target_test = l:class_name . '.' . l:method_name
  let l:cmd = printf("sf apex run test --tests '%s' --target-org %s -y", l:target_test, g:alias)

  echo printf("Executing selected test: %s", l:target_test)
  call util#open_term(l:cmd)
endfunction

