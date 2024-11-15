function! sobject#controller(ex_cmd, extra_arg) abort
  if a:ex_cmd ==# 'list'
    call sobject#describe_global()
  elseif a:ex_cmd ==# 'describe'
    call sobject#describe(a:extra_arg)
  endif
endfunction

function! sobject#list() abort
  let l:cmd = printf('sf sobject list -o %s', g:alias)
  let l:cmd_output = system(l:cmd)
  let l:parsed_output = util#parse_output(l:cmd_output)
  let l:sobjects = split(l:parsed_output, '\n')
  call util#list('SObjectList', l:sobjects, 'sobject#describe', 'execute SObjectDescribe')
endfunction

function! sobject#describe(sobject_name) abort
  let l:sobject_name = a:sobject_name
  if match(l:sobject_name, ' \| ') >= 0
    let l:parts = split(l:sobject_name, ' \| ')
    let l:sobject_name = trim(l:parts[0])
    echo l:sobject_name
  endif

  let l:cmd = printf('sf sobject describe --sobject %s -o %s', l:sobject_name, g:alias)
  let l:cmd_output = system(l:cmd)
  let l:parsed_output = util#parse_output(l:cmd_output)
  let l:fields = json_decode(l:l:parsed_output).fields

  let header_format = {'label': 'label', 'name': 'name', 'type': 'type', 'inlineHelpText': 'help text'}
  let header  = sobject#sobject_field_new(header_format).format_for_display()

  let l:display_fields = [header]
  call extend(l:display_fields, map(copy(l:fields), { k, v -> sobject#sobject_field_new(v).format_for_display()}))

  call util#list('SobjectFields', l:display_fields, '', '')
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

function! sobject#describe_global() abort
  call org#set_displayed_value()

  let l:api_url = g:instance_url . '/services/data/v' . g:api_version . '/sobjects/'
  let l:auth_header = 'Authorization: Bearer ' . g:access_token
  let l:curl_command = 'curl -s "' . l:api_url . '" -H "' . l:auth_header . '"'
  let l:output = system(l:curl_command)
  let l:sobjects = json_decode(l:output).sobjects
  let l:display_sobjects = []
  for sobject in l:sobjects
    let l:label = sobject.label
    let l:name = printf("%-40s", sobject.name)
    let l:line = l:name." | ".l:label
    call add(l:display_sobjects, l:line)
  endfor
  call util#list('SObjectListGlobal', l:display_sobjects, 'sobject#describe', 'execute SObjectDescribe')
endfunction
