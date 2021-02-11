fun! ECY2_main#Init()
"{{{
  " test
  call rpc_main#NewClient('python C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou/python/client_main.py')
"}}}
endf

fun! ECY2_main#DoCmd(cmd_name, param_list)
"{{{

  " call ECY2_main#DoCmd('gopls.tidy', [])
  let l:send_msg = {'event_name': 'DoCmd', 'params': {
                \'buffer_content': GetCurrentBufferContent(), 
                \'buffer_path': ECY#utility#GetCurrentBufferPath(), 
                \'buffer_id': GetBufferIDChange(),
                \'param_list': a:param_list,
                \'cmd_name': a:cmd_name
                \}}
  call RPCEventsAll(l:send_msg)
"}}}
endf

fun! ECY2_main#GetCodeLens()
"{{{
  let l:send_msg = {'event_name': 'GetCodeLens', 'params': {
                \'buffer_content': GetCurrentBufferContent(), 
                \'buffer_path': ECY#utility#GetCurrentBufferPath(), 
                \'buffer_id': GetBufferIDChange()
                \}}
  call RPCEventsAll(l:send_msg)
"}}}
endf

fun! ECY2_main#DoCodeAction()
"{{{

  " call ECY2_main#DoCmd('gopls.tidy', [])
  let l:send_msg = {'event_name': 'DoCodeAction', 'params': {
                \'buffer_content': GetCurrentBufferContent(), 
                \'buffer_path': ECY#utility#GetCurrentBufferPath(), 
                \'buffer_id': GetBufferIDChange()
                \}}
  call RPCEventsAll(l:send_msg)
"}}}
endf
