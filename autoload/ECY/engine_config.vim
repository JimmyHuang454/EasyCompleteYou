fun! ECY#engine_config#Init() abort
  try
    call s:Load()
  catch 
  endtry
endf

fun! s:Load() abort
"{{{
  let g:ECY_engine_config_dir = g:ECY_base_dir . '/engine_config'
  let g:ECY_engine_default_config_path = g:ECY_engine_config_dir . '/default_config.json'

  let g:ECY_default_value = readfile(g:ECY_engine_default_config_path)
  let g:ECY_default_value = json_decode(join(g:ECY_default_value, "\n"))

  if !exists('g:ECY_engine_config')
    let g:ECY_engine_config = {}
  endif

  for item in keys(g:ECY_default_value)
    if !has_key(g:ECY_engine_config, item)
      let g:ECY_engine_config[item] = {}
    endif

    for item2 in keys(g:ECY_default_value[item])
      if !has_key(g:ECY_engine_config[item], item2)
        let g:ECY_engine_config[item][item2] = 
              \g:ECY_default_value[item][item2]['default_value']
      endif
    endfor
  endfor
"}}}
endf


fun! ECY#engine_config#GetEngineConfig(engine_name, opts) abort
"{{{
  if !has_key(g:ECY_engine_config, a:engine_name) || 
        \!has_key(g:ECY_engine_config[a:engine_name], a:opts)
    return 'nothing'
  endif
  let l:temp = g:ECY_engine_config[a:engine_name][a:opts]
  if type(l:temp) == v:t_string && len(l:temp) != 0 && l:temp[0] == '&'
    let g:ECY_config_var = l:temp[0]
    try
      exe printf('let g:ECY_config_var = %s' % (l:temp[1:]))
    catch 
    endtry
    let g:ECY_engine_config[a:engine_name][a:opts] = g:ECY_config_var
    return g:ECY_engine_config[a:engine_name][a:opts]
  else
    return l:temp
  endif
"}}}
endf
