if exists('g:loaded_sfdx')
  finish
endif
let g:loaded_sfdx = 1

command! SfdxLogin call sfdx#web_login()
command! SfdxList call sfdx#org_list()
command! SfdxDeploy call sfdx#deploy()
command! SfdxRetrieve call sfdx#retrieve()
command! -nargs=1 SfdxSoql call sfdx#execute_soql(<q-args>)

