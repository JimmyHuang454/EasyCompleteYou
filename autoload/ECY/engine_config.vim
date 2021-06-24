fun! ECY#engine_config#Init() abort
  let g:ECY_engine_config_dir = g:ECY_base_dir . '/engine_config'
  try
    call s:Load()
  catch
  endtry
endf

fun! s:Load() abort
"{{{
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
      let l:line = split(item2, '\.')
      let l:name_len = len(l:line)
      let l:user_config = g:ECY_engine_config[item]
      if l:name_len > 1
        let i = 0
        while i < (l:name_len - 1)
          if !has_key(l:user_config, l:line[i])
            let l:user_config[l:line[i]] = {}
          endif
          let l:user_config = l:user_config[l:line[i]]
          let i += 1
        endw
        let l:name = l:line[l:name_len - 1]
      else
        let l:name = item2
      endif

      if !has_key(l:user_config, l:name)
        let l:user_config[l:name] = g:ECY_default_value[item][item2]['default_value']
      endif

    endfor
  endfor
"}}}
endf


fun! ECY#engine_config#GetEngineConfig(engine_name, key) abort
"{{{
  if !has_key(g:ECY_engine_config, a:engine_name)
    return ''
  endif

  let l:line = split(a:key, '\.')
  let l:name_len = len(l:line)
  let l:user_config = g:ECY_engine_config[a:engine_name]
  if l:name_len > 1
    let i = 0
    while i < (l:name_len - 1)
      if !has_key(l:user_config, l:line[i])
        return ''
      endif
      let l:user_config = l:user_config[l:line[i]]
      let i += 1
    endw
    let l:name = l:line[l:name_len - 1]
  else
    let l:name = a:key
  endif

  if !has_key(l:user_config, l:name)
    return ''
  endif
  return l:user_config[l:name]
"}}}
endf
