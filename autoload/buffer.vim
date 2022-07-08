let s:buffer_name = 'apex list//'

function! buffer#open_list(list) abort
  " if buffer exists
  if bufexists(s:buffer_name)
    " if buffer display in window
    let winid = bufwinid(s:buffer_name)
    if winid isnot# -1
      call win_gotoid(winid)
      call buffer#on_bufread_list(a:list)
    else
      execute 'sbuffer' s:buffer_name
      call buffer#on_bufread_list(a:list)
    endif
  else
    execute 'new' s:buffer_name
    call buffer#on_bufread_list(a:list)
  endif
endfunction

function! buffer#on_bufread_list(list) abort
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

