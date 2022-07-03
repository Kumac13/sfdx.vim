let s:list_buffer = 'apex list//'

function! buffer#open_list(list) abort
  " if buffer exists
  if bufexists(s:list_buffer)
    " if buffer display in window
    let winid = bufwinid(s:list_buffer)
    if winid isnot# -1
      call win_gotoid(winid)
      call buffer#on_bufread_list(a:list)
    else
      execute 'sbuffer' s:list_buffer
      call buffer#on_bufread_list(a:list)
    endif
  else
    execute 'new' s:list_buffer
    call buffer#on_bufread_list(a:list)
  endif
endfunction

function! buffer#on_bufread_list(list) abort
  set buftype=nofile

  nnoremap <silent> <buffer>
        \   <Plug>(session-close)
        \   :<C-u>bwipeout!<CR>
  nnoremap <silent> <buffer>
        \   <Plug>(session-open)
        \   :<C-u>call session#load_session(trim(getline('.')))<CR>

  nmap <buffer> q <Plug>(session-close)
  nmap <buffer> <CR> <Plug>(session-open)

  let lists = a:list
  if empty(lists)
    call setline(1, '--- no list exist ---')
    return
  endif

  "" delete buffer contents
  %delete _
  call setline(1, lists)
endfunction

