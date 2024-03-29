fun! ECY#engine_config#Init() abort
  let g:ECY_engine_config_dir = g:ECY_base_dir . '/engine_config'
  let g:ECY_installer_config_path = g:ECY_python_script_folder_dir . '/arch_config.json'

  call s:LoadEngine()
  call ECY#engine_config#LoadInstallerInfo()
endf

fun! s:LoadEngine() abort
"{{{
  let g:ECY_engine_default_config_path = g:ECY_engine_config_dir . '/default_config.json'

  let g:ECY_default_value = readfile(g:ECY_engine_default_config_path)
  let g:ECY_default_value = json_decode(join(g:ECY_default_value, "\n"))

  if !exists('g:ECY_config')
    let g:ECY_config = {}
  endif

  for item in keys(g:ECY_default_value)
    if !has_key(g:ECY_config, item)
      let g:ECY_config[item] = {}
    endif
    for item2 in keys(g:ECY_default_value[item])
      let l:line = split(item2, '\.')
      let l:name_len = len(l:line)
      let l:user_config = g:ECY_config[item]
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

fun! ECY#engine_config#LoadInstallerInfo() abort
"{{{
  let g:ECY_installer_config = {}
  if !filereadable(g:ECY_installer_config_path)
    return
  endif

  let l:temp = readfile(g:ECY_installer_config_path)
  let g:ECY_installer_config = json_decode(join(l:temp, "\n"))
  if g:os != 'Windows'
    " new file need sudo again
    call ECY#rpc#ECY2_job#start('sudo chmod -R 775 ' . g:ECY_base_dir, {})
  endif
"}}}
endf

fun! ECY#engine_config#GetEngineConfig(engine_name, key) abort
"{{{
  if !has_key(g:ECY_config, a:engine_name)
    return v:null
  endif

  let l:line = split(a:key, '\.')
  let l:name_len = len(l:line)
  let l:user_config = g:ECY_config[a:engine_name]
  if l:name_len > 1
    let i = 0
    while i < (l:name_len - 1)
      if !has_key(l:user_config, l:line[i])
        return v:null
      endif
      let l:user_config = l:user_config[l:line[i]]
      let i += 1
    endw
    let l:name = l:line[l:name_len - 1]
  else
    let l:name = a:key
  endif

  if !has_key(l:user_config, l:name)
    return v:null
  endif
  return l:user_config[l:name]
"}}}
endf

fun! ECY#engine_config#GetInstallerInfo(installer_name) abort
"{{{
  if !has_key(g:ECY_installer_config, a:installer_name)
    return {}
  endif
  return g:ECY_installer_config[a:installer_name]
"}}}
endf
