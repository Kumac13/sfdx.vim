" ==== PMD ====
" - Need to download pmd
function! pmd#controller(ex_cmd)
  if a:ex_cmd ==# 'pmd_current_file'
    call s:pmd_current_file()
  endif
endfunction

function! s:pmd_current_file()
  echo "\nExecuting Apex Pmd..."
  let pmd = NewPmd()
  call pmd.perform()
endfunction

let g:pmd = {'run_path': $PMD_PATH, 'target_path':'', 'result':''}

function! NewPmd() abort
  let self = copy(g:pmd)
  let self.target_path = expand('%:p')
  return self
endfunction

function! pmd.command() dict abort
  let l:ruleset_path = $HOME.'/.vim/plugged/sfdx.vim/rulesets/apex_ruleset.xml'
  return join([self.run_path, 'pmd', '-d', self.target_path, '-R ',  l:ruleset_path,' -f csv'], ' ' )
endfunction

function! pmd.perform() dict abort
  let self.result = split(system(self.command()), '\n')
  let l:regex = 'net\.sourceforge\.pmd\.PMD\|parseRuleReferenceNode\|WARNING'

  let filterd = filter(self.result, {-> !util#is_regex_match(v:val, l:regex)})

  let parsed = map(copy(filterd), {-> NewPmdResult(v:val).display()})

  call util#open_list(parsed)

endfunction

let g:pmd_result = {'file': '', 'column':'', 'rule': '', 'description':''}

function! pmd_result.display() dict abort
  return printf('%s | %s | %s | %s', self.file, self.column, self.rule, self.description)
endfunction

function! NewPmdResult(result_row) abort
  let self = copy(g:pmd_result)
  let split_item = split(a:result_row, ',')
  let self.file = expand('%:p')
  let self.column = trim(split_item[4], '"', 0)
  let self.rule = trim(split_item[7], '"', 0)
  let self.description = trim(split_item[5], '"', 0)
  return self
endfunction
