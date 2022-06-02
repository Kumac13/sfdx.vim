if exists('g:loaded_sfdx')
  finish
endif
let g:loaded_sfdx = 1

command! SfdxList call sfdx#main('org','list')
command! SfdxLogin call sfdx#main('auth','login')
command! SfdxDeploy call sfdx#main('source', 'deploy')
command! SfdxRetrieve call sfdx#main('source', 'retrieve')
command! -nargs=1 SfdxSoql call sfdx#execute_soql(<q-args>)

