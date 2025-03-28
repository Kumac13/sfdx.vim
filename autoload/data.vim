" ==== force:data ====
function! data#controller(ex_cmd, query)
  if a:ex_cmd ==# 'execute_soql'
    call s:execute_soql(a:query)
  elseif a:ex_cmd ==# 'execute_markdown_soql_block'
    call data#execute_markdown_soql_block()
  endif
endfunction

" Get soql query result
function! s:execute_soql(query) abort
  let l:cmd = printf("sf data query --query '%s' -r human --target-org %s", a:query, g:alias)
  call util#open_term(l:cmd)
endfunction

" Markdownファイル内のSOQLコードブロックを実行する
function! data#execute_markdown_soql_block() abort
  " 現在の行番号を取得
  let l:current_line = line('.')
  let l:start_line = 0
  let l:end_line = 0

  " カーソルより上の行を検索して```soqlを見つける
  let l:line_num = l:current_line
  while l:line_num > 0
    let l:line = getline(l:line_num)
    if l:line =~# '^\s*```\s*soql'
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
    " ブロック内の全行を取得
    let l:lines = getline(l:start_line, l:end_line)

    " コメント行を削除
    let l:query_lines = []
    for l:line in l:lines
      if l:line !~# '^\s*\/\/'
        call add(l:query_lines, l:line)
      endif
    endfor

    " クエリを結合
    let l:query = join(l:query_lines, ' ')

    " 空白文字を適切に処理
    let l:query = substitute(l:query, '\s\+', ' ', 'g')
    let l:query = trim(l:query)

    " クエリが空でなければ実行
    if !empty(l:query)
      call s:execute_soql(l:query)
      return 1
    endif
  endif

  echo "カーソルがSOQLコードブロック内にないか、有効なクエリがありません"
  return 0
endfunction
