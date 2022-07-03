function util#is_regex_match(line, regex) abort
  let match_result = match(a:line, a:regex)
  if match_result < 0
    return 0
  endif
  return 1
endfunction

