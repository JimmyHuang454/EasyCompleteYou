fun! ECY2_main#Init()
"{{{
  let l:run_cmd = g:ECY_python_cmd . ' ' . g:ECY_python_script_folder_path . '/client_main.py'
  if g:ECY_is_debug
    let l:run_cmd .= ' --debug_log'
  endif
  call ECY#rpc#rpc_main#NewClient(l:run_cmd)
"}}}
endf

fun! ECY2_main#DoCmd(cmd_name, param_list)
"{{{

  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'param_list': a:param_list,
                \'cmd_name': a:cmd_name,
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'DoCmd', 'params': l:params})
"}}}
endf

fun! ECY2_main#CheckAllEngine()
"{{{

  let l:engine_list = []
  for item in g:ECY_all_buildin_engine
    call add(l:engine_list, item['engine_name'])
  endfor

  let l:params = {'engine_list': l:engine_list}

  call ECY#rpc#rpc_event#call({'event_name': 'OnCheckEngine', 'params': l:params})
"}}}
endf

fun! ECY2_main#GetCodeLens()
"{{{
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'GetCodeLens', 'params': l:params})
"}}}
endf

fun! ECY2_main#GetWorkSpaceSymbol()
"{{{
  let l:params = {}

  call ECY#rpc#rpc_event#call({'event_name': 'OnWorkSpaceSymbol', 'params': l:params})
"}}}
endf

fun! ECY2_main#DoCodeAction()
"{{{

  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'DoCodeAction', 'params': l:params})
"}}}
endf

fun! ECY2_main#IsWorkAtCurrentBuffer()
"{{{
  if exists( 'b:ECY_is_work_at_current_buffer' )
    return b:ECY_is_work_at_current_buffer
  endif

  let l:file_type = &filetype
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
