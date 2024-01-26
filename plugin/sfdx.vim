if exists('g:loaded_sfdx')
  finish
endif
let g:loaded_sfdx = 1

command! SfdxLogin call sfdx#main('auth','login')
command! SfdxOrgList call sfdx#main('org','list')
command! SfdxOrgOpen call sfdx#main('org','open')
command! SfdxDeploy call sfdx#main('source', 'deploy')
command! SfdxCreateApexFile call sfdx#main('apex', 'create_apex_file')
command! SfdxRunApexTestClass call sfdx#main('apex', 'run_apex_test_cls')
command! SfdxRunApexTestClassWithCoverage call sfdx#main('apex', 'run_apex_test_cls_with_coverage')
command! -range SfdxRunApexTestSelected <line1>,<line2>call sfdx#main('apex', 'run_apex_test_selected')
command! SfdxDebugLogList call sfdx#main('apex', 'apex_log_list')
command! SfdxDebugLogActive call sfdx#main('apex', 'apex_log_tail')
command! SfdxRetrieve call sfdx#main('source', 'retrieve')
command! -nargs=1 SfdxSoql call sfdx#main('data', 'execute_soql',<q-args>)
command! -range SfdxApexExecute <line1>,<line2>call sfdx#main('apex','apex_execute')
command! SfdxPmdCurrentFile call sfdx#main('pmd', 'pmd_current_file')
command! SfdxSObjectList call sfdx#main('sobject', 'list')
command! -nargs=1 SfdxSObjectDescribe call sfdx#main('sobject', 'describe', <q-args>)
command! SfdxAlias call alias#list()

