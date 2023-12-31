function! sobject#controller(ex_cmd, extra_arg) abort
  if a:ex_cmd ==# 'list'
    call sobject#list()
  elseif a:ex_cmd ==# 'describe'
    call sobject#describe(a:extra_arg)
  endif
endfunction

function! sobject#list() abort
  let l:cmd = printf('sf sobject list -o %s', g:alias)
  let l:sobjects = split(system(l:cmd), '\n')
  call util#list('SObjectList', l:sobjects, 'sobject#describe', 'execute SObjectDescribe')
endfunction

function! sobject#describe(sobject_name) abort
  let l:cmd = printf('sf sobject describe --sobject %s -o %s', a:sobject_name, g:alias)
  let l:fields = json_decode(system(l:cmd)).fields
  call map(l:fields, { -> sobject#sobject_field_new(v:val).format_for_display()})
  call util#list('SobjectFields', l:fields, '', '')
endfunction

let g:sobject_field = {'label':'', 'name':'', 'type':'', 'inlineHelpText':''}

function! sobject#sobject_field_new(json_field) abort
  let self = copy(g:sobject_field)
  let self.label = a:json_field.label
  let self.name = a:json_field.name
  let self.type = a:json_field.type
  let self.inlineHelpText = a:json_field.inlineHelpText
  return self
endfunction

function! sobject_field.format_for_display() abort
  let l:label = printf("%-40s", self.label)
  let l:name = printf("%-40s", self.name)
  let l:type = printf("%-10s", self.type)
  let l:help_text = self.inlineHelpText != v:null ? printf("%.100s", self.inlineHelpText) : ''
  return join([l:name, l:type, self.label, l:help_text], ' | ')
endfunction
