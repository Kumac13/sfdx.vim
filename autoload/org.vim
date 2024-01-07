function! org#controller(ex_cmd) abort
  if a:ex_cmd ==# 'list'
    call org#list()
  elseif a:ex_cmd ==# 'open'
    call s:open()
  endif
endfunction

function! s:list() abort
  call util#open_term('sf org list')
endfunction

function! s:open() abort
  let l:cmd = printf('sf org open -o %s', g:alias)
  execute system(l:cmd)
endfunction

let g:sf_org = {'org_type':'','user_name':'', 'alias': '', 'status':'', 'org_id':'', 'is_sandbox':'', 'instance_url':''}

function! org#sf_org_new(json_field, org_type) abort
  let self = copy(g:sf_org)
  let self.org_type = a:org_type
  let self.user_name = get(a:json_field, 'username', '')
  let self.alias = get(a:json_field, 'alias', '')
  let self.status = get(a:json_field, 'connectedStatus', '')
  let self.org_id = get(a:json_field, 'orgId', '')
  let self.is_sandbox = get(a:json_field, 'isSandbox', v:false)
  let self.instance_url = get(a:json_field, 'instanceUrl', '')

  return self
endfunction

function! sf_org.format_for_display() abort
  let l:org_type = printf("%-10s", self.org_type)
  let l:user_name = printf("%-15s", self.user_name)
  let l:alias = printf("%-10s", self.alias)
  let l:status = printf("%-15s", self.status)
  let l:org_id = printf("%-18s", self.org_id)
  let l:is_sandbox = printf("%-10s", self.is_sandbox ==# 'is_sandbox' ? 'is_sandbox' : self.is_sandbox ? 'true': 'false')
  return join([l:org_type, l:user_name, l:alias, l:status, l:org_id, l:is_sandbox, self.instance_url], ' | ')
endfunction

function! org#list() abort
  let l:cmd = printf('sf org list --json')
  let l:orgs = json_decode(system(l:cmd)).result

  let l:header_fields = {'username':'user name', 'alias': 'alias', 'connectedStatus': 'status', 'orgId':'org_id', 'isSandbox': 'is_sandbox', 'instanceUrl': 'instance_url'}
  let header = org#sf_org_new(l:header_fields, 'org_type').format_for_display()

  let l:display_orgs = [header]

  if !empty(l:orgs.other)
    for org in l:orgs.other
      let l:formatted_orgs = org#sf_org_new(org, 'other').format_for_display()
      call add(l:display_orgs, l:formatted_orgs)
    endfor
  endif

  call util#list('Orgs', l:display_orgs, '', '')
endfunction
