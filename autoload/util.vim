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

