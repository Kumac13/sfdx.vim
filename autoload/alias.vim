function! alias#list() abort
  let l:alias_json = join(readfile($HOME.'/.sfdx/alias.json'), '\n')
  let l:json = json_decode(alias_json)
  let l:orgs = get(l:json, 'orgs')
  let l:aliases = []

  call add(l:aliases, 'current alias | alias | user name')
  for [l:key, l:value] in items(l:orgs)
    let l:line = l:key.' | '.l:value

    if exists("g:alias") && g:alias ==# l:key
      let l:line = '      ✓       | '.l:line
    else
      let l:line = '              | '.l:line
    endif

    call add(l:aliases, l:line)
  endfor

  call util#list('Alias', l:aliases, 'alias#set_current_alias', 'set current alias.')
endfunction

function! alias#set_current_alias(alias) abort
  let g:alias = trim(split(a:alias, '|')[1])
  echomsg 'set current alias: '.g:alias
  bdelete
endfunction
