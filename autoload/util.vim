function util#is_regex_match(line, regex) abort
  let match_result = match(a:line, a:regex)
  if match_result < 0
    return 0
  endif
  return 1
endfunction

function util#open_term(cmd) abort
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


let s:buffer_name = 'apex list//'

function! util#open_list(list) abort
  " if buffer exists
  if bufexists(s:buffer_name)
    " if buffer display in window
    let winid = bufwinid(s:buffer_name)
    if winid isnot# -1
      call win_gotoid(winid)
      call util#on_bufread_list(a:list)
    else
      execute 'sbuffer' s:buffer_name
      call util#on_bufread_list(a:list)
    endif
  else
    execute 'new' s:buffer_name
    call util#on_bufread_list(a:list)
  endif
endfunction

function! util#on_bufread_list(list) abort
  set buftype=nofile

  nnoremap <silent> <buffer>
        \  <Plug>(session-close)
        \  :<C-u>bdelete!<CR>
  nmap <buffer> q <Plug>(session-close)
  nnoremap <silent> <buffer>
        \  <Plug>(buffer-open)
        \  :<C-u>call apex#debug#get_log()<CR>
  nmap <buffer> <CR> <Plug>(buffer-open)

  let lists = a:list
  if empty(lists)
    call setline(1, '--- no list exist ---')
    return
  endif

  "" delete buffer contents
  %delete _
  call setline(1, lists)
endfunction


