fun! ECY#exe_cmd#ExecuteCommand(opts) abort
"{{{
  if has_key(a:opts, 'engine_name')
    let l:engine_name = a:opts['engine_name']
  else
    let l:engine_name = ECY#engine#GetBufferEngineName()
  endif

  if !has_key(a:opts, 'cmd_name')
    return
  endif

  let l:params = {'cmd_params': a:opts['cmd_name']}

  if has_key(a:opts, 'cmd_params')
    let l:params['cmd_params'] = a:opts['cmd_params']
  endif

  call ECY#rpc#rpc_event#call({'event_name': 'ExecuteCommand', 
        \'params': l:params,
        \'engine_name': l:engine_name})
"}}}
endf
