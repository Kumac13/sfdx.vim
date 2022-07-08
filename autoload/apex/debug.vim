let g:debug_log_result = {'Id': '', 'operation':'','status':'','start_time':''}

function! debug_log_result.display() dict abort
  let l:Id = self.Id
  let l:status = printf("%.40s", self.status)
  let l:operation = printf("%-16s", self.operation)
  return join([l:Id, l:operation, self.start_time, l:status], ' | ')
endfunction

function! apex#debug#debug_log_result_new(result_row) abort
  let self = copy(g:debug_log_result)
  let self.Id = a:result_row.Id
  let self.operation = a:result_row.Operation
  let self.status = a:result_row.Status
  let self.start_time = a:result_row.StartTime
  return self
endfunction

function! apex#debug#list()
  let l:result = json_decode(system('sfdx force:apex:log:list -u kumac --json')).result
  call map(l:result, { -> apex#debug#debug_log_result_new(v:val).display()})
  call buffer#open_list(l:result)
endfunction

" Activates debug logging
function! apex#debug#active_debug()
  let l:cmd = printf("sfdx force:apex:log:tail -u %s", g:alias)
  call util#open_term(l:cmd)
endfunction
