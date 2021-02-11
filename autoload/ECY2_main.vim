fun! ECY2_main#Init()
"{{{
  " test
  call rpc_main#NewClient('python C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou/python/client_main.py')
"}}}
endf

fun! ECY2_main#DoCmd(cmd_name, param_list)
"{{{

  let l:params = {
                \'buffer_path': ECY#utility#GetCurrentBufferPath(), 
                \'buffer_line': GetCurrentLine(), 
                \'buffer_position': GetCurrentLineAndPosition(), 
                \'buffer_content': GetCurrentBufferContent(), 
                \'param_list': a:param_list,
                \'cmd_name': a:cmd_name,
                \'buffer_id': GetBufferIDNotChange()
                \}}

  call RPCCall({'event_name': 'DoCmd', 'params': l:params})
"}}}
endf

fun! ECY2_main#GetCodeLens()
"{{{
  let l:params = {
                \'buffer_path': ECY#utility#GetCurrentBufferPath(), 
                \'buffer_line': GetCurrentLine(), 
                \'buffer_position': GetCurrentLineAndPosition(), 
                \'buffer_content': GetCurrentBufferContent(), 
                \'buffer_id': GetBufferIDNotChange()
                \}}

  call RPCCall({'event_name': 'GetCodeLens', 'params': l:params})
"}}}
endf

fun! ECY2_main#DoCodeAction()
"{{{

  let l:params = {
                \'buffer_path': ECY#utility#GetCurrentBufferPath(), 
                \'buffer_line': GetCurrentLine(), 
                \'buffer_position': GetCurrentLineAndPosition(), 
                \'buffer_content': GetCurrentBufferContent(), 
                \'buffer_id': GetBufferIDNotChange()
                \}}

  call RPCCall({'event_name': 'DoCodeAction', 'params': l:params})
"}}}
endf
