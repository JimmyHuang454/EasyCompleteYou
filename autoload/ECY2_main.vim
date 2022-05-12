fun! ECY2_main#Init() abort
"{{{
  let g:ECY_is_debug = get(g:,'ECY_is_debug', v:false)

  let g:ECY_debug_log_file_path = 
        \get(g:,'ECY_debug_log_file_path', g:ECY_python_script_folder_dir . '/ECY_debug.log')

  let g:ECY_disable_for_files_larger_than_kb
        \= ECY#engine_config#GetEngineConfig('ECY', 'disable_for_files_larger_than_kb')

  let g:ECY_file_type_blacklist
        \= ECY#engine_config#GetEngineConfig('ECY', 'file_type_blacklist')

  let l:run_cmd = g:ECY_client_main_path
  let l:run_cmd .= ' --sources_dir ' . g:ECY_source_folder_dir
  let l:run_cmd .= ' --log_path ' . g:ECY_debug_log_file_path
  if g:ECY_is_debug
    let l:run_cmd .= ' --debug_log'
  endif
  let g:ECY_main_cmd = l:run_cmd
  call ECY#rpc#rpc_main#NewClient()
"}}}
endf

fun! s:GetEngineName(input) abort
"{{{
  if len(a:input) == 0
    return ECY#engine#GetBufferEngineName()
  endif
  return a:input[0]
"}}}
endf

fun! ECY2_main#ExecuteCommand(engine_name, cmd_name, cmd_params) abort
"{{{

  if type(a:cmd_params) != v:t_list
    call ECY#utils#echo("params should be a list.")
    return
  endif

  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'cmd_params': a:cmd_params,
                \'cmd_name': a:cmd_name,
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'ExecuteCommand', 
        \'params': l:params,
        \'engine_name': a:engine_name})
"}}}
endf

fun! ECY2_main#GetExecuteCommand(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  call ECY#rpc#rpc_event#call({'event_name': 'GetExecuteCommand', 'params': {},
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#CheckAllEngine() abort
"{{{

  let l:engine_list = []
  for item in g:ECY_all_buildin_engine
    call add(l:engine_list, item['engine_name'])
  endfor

  let l:params = {'engine_list': l:engine_list}

  call ECY#rpc#rpc_event#call({'event_name': 'OnCheckEngine', 'params': l:params})
"}}}
endf

fun! ECY2_main#ReStart(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  call ECY#rpc#rpc_event#call({'event_name': 'ReStart', 'params': {},
        \'engine_name': l:engine_name})
  doautocmd <nomodeline> EasyCompleteYou2 BufEnter " do cmd
"}}}
endf

fun! s:GetInstallerName(engine_name) abort
"{{{
  let l:installer_name = ''
  let l:info = ECY#engine#GetEngineInfo(a:engine_name)

  if has_key(l:info, 'installer_path')
    let l:installer_name = l:info['installer_path']
  endif

  return l:installer_name
"}}}
endf

fun! ECY2_main#InstallLS(engine_name) abort
"{{{

  call ECY#utils#TermStart(printf('%s --install "%s" --sources_dir "%s" --engine_name "%s"',
        \ g:ECY_client_main_path, s:GetInstallerName(a:engine_name), g:ECY_source_folder_dir, a:engine_name), 
        \{'exit_cb': function('ECY#engine_config#LoadInstallerInfo')})
"}}}
endf

fun! ECY2_main#UnInstallLS(engine_name) abort
"{{{
  call ECY#utils#TermStart(printf('%s --uninstall "%s" --sources_dir "%s" --engine_name "%s"',
        \ g:ECY_client_main_path, s:GetInstallerName(a:engine_name), g:ECY_source_folder_dir, a:engine_name),
        \{'exit_cb': function('ECY#engine_config#LoadInstallerInfo')})
"}}}
endf

fun! ECY2_main#GetCodeLens(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'GetCodeLens', 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#Rename(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:new_name = ECY#utils#Input('New name: ')
  if l:new_name == ''
    return
  endif
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'new_name': l:new_name, 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'Rename', 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#OnTypeFormatting() abort
"{{{
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnTypeFormatting', 'params': l:params})
"}}}
endf

fun! ECY2_main#Format(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'Format', 'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#GetWorkSpaceSymbol(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnWorkSpaceSymbol', 
        \'params': l:params, 'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#GetDocumentSymbol(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnDocumentSymbol', 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#FindReferences(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'FindReferences', 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#SeleteRange(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'SelectionRange', 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! s:FoldingRange(engine_name, is_current_line) abort
"{{{
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'is_current_line': a:is_current_line, 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'FoldingRange', 
        \'params': l:params, 
        \'engine_name': a:engine_name})
"}}}
endf

fun! ECY2_main#FoldingRangeCurrentLine(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  call s:FoldingRange(l:engine_name, 1)
"}}}
endf

fun! ECY2_main#FoldingRange(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  call s:FoldingRange(l:engine_name, 0)
"}}}
endf

fun! ECY2_main#ClangdSwitchHeader(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'SwitchSourceHeader', 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#PrepareCallHierarchy() abort
"{{{
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'PrepareCallHierarchy', 'params': l:params})
"}}}
endf

fun! ECY2_main#Goto(engine_name, event_name, is_preview) abort
"{{{
  let l:engine_name = a:engine_name
  if l:engine_name == ''
    let l:engine_name = ECY#engine#GetBufferEngineName()
  endif

  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'is_preview': a:is_preview, 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': a:event_name, 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#Hover(...) abort
"{{{
  let l:engine_name = s:GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnHover', 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY2_main#DoCodeAction(params) abort
"{{{

  if a:params['range_type'] == 'selected_range'
    let l:buffer_range = ECY#utils#GetSelectRange()
  else
    let l:buffer_range = ECY#utils#GetCurrentLineRange()
  endif

  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_range': l:buffer_range, 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'DoCodeAction', 'params': l:params})
"}}}
endf

fun! ECY2_main#IsWorkAtCurrentBuffer() abort
"{{{
  if exists( 'b:ECY_is_work_at_current_buffer' )
    return b:ECY_is_work_at_current_buffer
  endif

  if ECY#engine#GetBufferEngineName() == 'ECY_engines.vim_lsp.vim_lsp'
    return v:false
  endif

  let l:file_type = ECY#utils#GetCurrentBufferFileType()
  for item in g:ECY_file_type_blacklist
    if l:file_type =~ item
      return v:false
    endif
  endfor

  let l:threshold = g:ECY_disable_for_files_larger_than_kb * 1024

  let b:ECY_is_work_at_current_buffer =
        \ l:threshold > 0 && getfsize(ECY#utils#GetCurrentBufferPath()) > l:threshold

  if b:ECY_is_work_at_current_buffer
    " only echo once because this will only check once
    call ECY#utils#echo("ECY unavailable: the file exceeded the max size.")
  endif

  let b:ECY_is_work_at_current_buffer = !b:ECY_is_work_at_current_buffer

  return b:ECY_is_work_at_current_buffer
"}}}
endf
