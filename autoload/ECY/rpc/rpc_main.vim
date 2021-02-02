fun! rpc_main#Init()
"{{{
  let g:rpc_params = []
  let g:rpc_result = ''
  let g:rpc_seq_id = -1
  let g:rpc_client_id = -1
  let s:request_list = []
  let s:is_timer_running = v:false
"}}}
endf

fun! rpc_main#echo(msg)
  echo a:msg
endf

fun! rpc_main#GetBuffer(msg) " return list
  echo a:msg
endf

fun! RPCEventsAll(msg)
"{{{
  if g:rpc_client_id == -1
    return
  endif
  let g:rpc_seq_id += 1
  let l:temp = {'type': 'event', 'event_name': a:msg, 'id': g:rpc_seq_id, 'params': a:msg['params']}
  let l:json = json_encode(l:temp) . "\n"

  call job#send(g:rpc_client_id, l:json)
"}}}
endf

fun! s:FallBack(original_request, res) " responce request that send from python 
"{{{
  let l:request_id = a:original_request['id']
  let l:res = a:res
  let l:res['request_id'] = l:request_id
  let l:res['type'] = 'fallback'

  call job#send(g:rpc_client_id, json_encode(l:res) . "\n")
"}}}
endf

fun! s:Do(timer_id)
"{{{
  let i = 0
  while i < len(s:request_list)
    let l:item = remove(s:request_list, 0) " pop first item to l:data_dict
    let l:data_dict = l:item['data']
    let l:type = l:data_dict['type']
    if l:type == 'call'
      let l:res = rpc_main#Call(l:data_dict['function_name'], l:data_dict['params'])
    elseif l:type == 'get'
      let l:res = rpc_main#Get(l:data_dict['variable_name'])
    endif
    call s:FallBack(l:data_dict, l:res)
    let i += 1
  endw
  let s:is_timer_running = v:false
  " call timer_start(1, function('s:Do'))
"}}}
endf

fun! rpc_main#Input(id, data, event)
"{{{
  for item in a:data
    if item == ''
      continue " an additional part when splitting line with '\n'
    endif
    let l:data_dict = json_decode(item)
    call add(s:request_list, {'id': a:id, 'data': l:data_dict})
    if s:is_timer_running == v:false
      let s:is_timer_running = v:true
      call timer_start(1, function('s:Do'))
    endif
  endfor
"}}}
endf

fun! rpc_main#NewClient(cmd)
"{{{
  let g:rpc_client_id = job#start(a:cmd, {
      \ 'on_stdout': function('rpc_main#Input')
      \ })
"}}}
endf

fun! rpc_main#Call(Function_name, params)
  "{{{
  let l:temp = 'let g:rpc_result = '. a:Function_name . '('
  let l:params_len = len(a:params)
  let g:rpc_params = a:params
  let i = 0

  for item in g:rpc_params
    let l:temp = l:temp . 'g:rpc_params['. i .']'
    let i += 1
    if i != l:params_len
      let l:temp = l:temp . ', '
    endif
  endfor
  let l:temp = l:temp . ')'
  try
    exe l:temp
  catch 
    return {'status': -1, 'res': '', 'msg': v:exception}
  endtry
  return {'status': 0, 'res': g:rpc_result, 'res_type': type(g:rpc_result)}
  "}}}
endf

fun! rpc_main#Get(variable_name)
  "{{{
  let l:temp = 'let g:rpc_result = '. a:variable_name
  try
    exe l:temp
  catch 
    return {'status': -1, 'res': '', 'msg': v:exception}
  endtry
  return {'status': 0, 'res': g:rpc_result, 'res_type': type(g:rpc_result)}
  "}}}
endf

call rpc_main#Init()
