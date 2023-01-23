function! force#schema#describe_sobject_schema(sobject) abort
  let l:cmd = printf('sfdx force:schema:sobject:describe -s %s --target-org %s', a:sobject,g:alias)
  let l:result = json_decode(system(l:cmd)).fields
  call map(l:result, { -> force#schema#field_new(v:val).display()})
  call util#open_list(l:result)
endfunction

let g:field = {'label':'', 'name':'','type':'','inlineHelpText':''}

function! force#schema#field_new(result_row) abort
  let self = copy(g:field)
  let self.label = a:result_row.label
  let self.name = a:result_row.name
  let self.type = a:result_row.type
  let self.inlineHelpText = a:result_row.inlineHelpText
  return self
endfunction

function! field.display() abort
  let l:label = printf("%-40s", self.label)
  let l:name = printf("%-40s", self.name)
  let l:type = printf("%-10s", self.type)
  let l:help_text = self.inlineHelpText != v:null ? printf("%.100s", self.inlineHelpText) : ''
  return join([l:name, l:type, self.label, l:help_text], ' | ')
endfunction
