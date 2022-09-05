" CustomObjectのリストがあるか確認
" CustomObjectのリストを取得
" リストを表示してオブジェクトを選択する
" 選択したオブジェクトのリストを表示
function! force#mdapi#controller(ex_cmd) abort
endfunction

function! s:listmetadata(metadata_type) abort
  let l:cmd = printf('sfdx force:mdapi:listmetadata -m %s -u %s', a:metadata_type, g:alias)
  echo system(l:cmd)
endfunction

function! Debug() abort
  call s:listmetadata('CustomObject')
endfunction

let g:custom_object = {'Id':''}
let g:cutom_field = {'Id':''}
