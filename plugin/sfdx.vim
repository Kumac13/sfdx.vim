if exists('g:loaded_sfdx')
  finish
endif
let g:loaded_sfdx = 1

command! SfdxList call sfdx#main('org','list')
command! SfdxLogin call sfdx#main('auth','login')
command! SfdxList call sfdx#main('auth','list')
command! SfdxDeploy call sfdx#main('source', 'deploy')
command! SfdxCreateApexFile call sfdx#main('apex', 'create_apex_file')
command! SfdxRunApexTestClass call sfdx#main('apex', 'run_apex_test_cls')
command! SfdxRetrieve call sfdx#main('source', 'retrieve')
command! -nargs=1 SfdxSoql call sfdx#main('data', 'execute_soql',<q-args>)

