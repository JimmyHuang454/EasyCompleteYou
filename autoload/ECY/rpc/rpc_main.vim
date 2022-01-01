fun! rpc_main#echo(msg)
  echo a:msg
endf

fun! s:Send(msg)
  if g:ECY_server_id == -1
    return
  endif
  let l:json = json_encode(a:msg) . "\n"
  call ECY#rpc#ECY2_job#send(g:ECY_server_id, l:json)
endf

fun! ECY#rpc#rpc_main#RPCEventsAll(msg, engine_name)
"{{{
  let g:rpc_seq_id += 1
  let l:temp = {'type': 'event', 'event_name': a:msg['event_name'], 'id': g:rpc_seq_id, 'params': a:msg['params'], 'engine_name': a:engine_name}
  call s:Send(l:temp)
"}}}
endf

fun! s:FallBack(original_request, res) " responce request that send from python 
"{{{
  let l:request_id = a:original_request['id']
  let l:res = a:res
  let l:res['request_id'] = l:request_id
  let l:res['type'] = 'fallback'
  call s:Send(l:res)
"}}}
endf

fun! s:Do(context)
"{{{
  let l:type = a:context['type']
  if l:type == 'call'
    let l:res = rpc_main#Call(a:context['function_name'], a:context['params'])
  elseif l:type == 'get'
    let l:res = rpc_main#Get(a:context['variable_name'])
  endif
  call s:FallBack(a:context, l:res)
"}}}
endf

fun! rpc_main#Input(id, data, event)
"{{{
  for item in a:data
    if item == ''
      continue " an additional part when splitting line with '\n'
    endif
    try
      let l:data_dict = json_decode(item)
      call s:Do(l:data_dict)
    catch 
    endtry
  endfor
"}}}
endf

fun! s:NewClient()
"{{{
  let g:ECY_server_id = ECY#rpc#ECY2_job#start(g:ECY_main_cmd, {
      \ 'on_stdout': function('rpc_main#Input')
      \ })
  call ECY#rpc#rpc_event#Init()
"}}}
endf

fun! s:ChomdExit(id, data, event) abort
  call s:NewClient()
endf

fun! ECY#rpc#rpc_main#NewClient()
"{{{
  if g:os != 'Windows'
    call ECY#rpc#ECY2_job#start('sudo chmod -R 750 ' . g:ECY_base_dir,
          \{'on_exit': function('s:ChomdExit')})
  else
    call s:NewClient()
  endif
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
    return {'status': -1, 'res': v:throwpoint, 'msg': v:exception}
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
    return {'status': -1, 'res': v:throwpoint, 'msg': v:exception}
  endtry
  return {'status': 0, 'res': g:rpc_result, 'res_type': type(g:rpc_result)}
  "}}}
endf

fun! rpc_main#Init()
"{{{
  let g:rpc_params = []
  let g:rpc_result = ''
  let g:rpc_seq_id = -1
  let g:ECY_server_id = -1
  let s:request_list = []
  let s:is_timer_running = v:false
"}}}
endf

call rpc_main#Init()
