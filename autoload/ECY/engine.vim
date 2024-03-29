
function! s:ChooseSource_Echoing() abort
  "{{{ the versatitle way. could be used in many versions of vim or neovim.
  let l:filetype = ECY#utils#GetCurrentBufferFileType()
  let l:info  = g:ECY_file_type_info2[l:filetype]
  while 1
    if len(l:info['available_sources']) == 0
      " show erro
      break
    endif
    let l:text1 = "Detected FileTpye--[".l:filetype."], available engines:\n"
    let l:text2 = "(Press ".'j/k'." to switch item that you want)\n------------------------------------------\n"
    let l:i     = 1
    for support_complete_name in l:info['available_sources']
      let l:item = string(l:i).".".support_complete_name."\n"
      if support_complete_name == l:info['filetype_using']
        let l:item = "  >> ".l:item
      else
        let l:item = "     ".l:item
      endif
      let l:text2 .= l:item
      let l:i += 1
    endfor
    let l:show_text = l:text1.l:text2
    echo l:show_text
    let l:c = nr2char(getchar())
    redraw!
    if l:c == "j"
      call s:ChooseSource('next')
    elseif l:c == "k"
      call s:ChooseSource('pre')
    else
      " a callback
      return
    endif
  endwhile
  "}}}
endfunction

function! s:ChooseSource(next_or_pre) abort
  "{{{ this will call by 'user_ui.vim'
  let l:filetype = ECY#utils#GetCurrentBufferFileType()
  if !has_key(g:ECY_file_type_info2, l:filetype)
    " server should init it first
    return
  endif
  let l:available_sources = g:ECY_file_type_info2[l:filetype]['available_sources']
  let l:current_using     = g:ECY_file_type_info2[l:filetype]['filetype_using']
  let l:available_sources_len = len(l:available_sources)
  let l:index             = 0
  for item in l:available_sources
    if l:current_using == item
      break 
    endif
    let l:index += 1
  endfor
  let l:choosing_source_index = 0

  if a:next_or_pre == 'next'
    let l:choosing_source_index = (l:index+1) % l:available_sources_len
  else
    let l:choosing_source_index = (l:index-1) % l:available_sources_len
  endif
  let l:choosing_source_index = l:available_sources[l:choosing_source_index]
  let g:ECY_file_type_info2[l:filetype]['filetype_using'] = l:choosing_source_index
  "}}}
endfunction

function! s:ChooseSource_cb() abort
"{{{
  doautocmd <nomodeline> EasyCompleteYou2 BufEnter " do cmd
  call ECY#diagnostics#ClearByEngineName(s:last_engine)
"}}}
endfunction

fun! ECY#engine#Do()
  "{{{
  let l:filetype = ECY#utils#GetCurrentBufferFileType()
  call ECY#engine#InitDefaultEngine(l:filetype)
  let s:last_engine = ECY#engine#GetBufferEngineName()

  " TODO
  call s:ChooseSource_Echoing()
  call s:ChooseSource_cb()
  "}}}
endf

fun! ECY#engine#Set(filetype, engine_name)
  "{{{
  call ECY#engine#InitDefaultEngine(a:filetype)
  let g:ECY_file_type_info2[a:filetype]['filetype_using'] = a:engine_name
  "}}}
endf

fun! s:InsertLeave()
"{{{
  let l:filetype = ECY#utils#GetCurrentBufferFileType()
  if !exists("g:ECY_file_type_info2[l:filetype]['last_engine_name']")
    return
  endif

  let g:ECY_file_type_info2[l:filetype]['filetype_using'] = 
        \g:ECY_file_type_info2[l:filetype]['last_engine_name']

  unlet g:ECY_file_type_info2[l:filetype]['last_engine_name']
  call ECY#rpc#rpc_event#OnBufferEnter()
"}}}
endf

fun! ECY#engine#MapEngine(opts)
"{{{
  let l:cmd = printf(
        \'inoremap <expr> %s ECY#engine#UseSpecifyEngineOnce("%s")',
        \a:opts['mapping'],
        \a:opts['engine'])

  if has_key(a:opts, 'input')
    let l:cmd = printf(
          \'inoremap <expr> %s ECY#engine#UseSpecifyEngineOnce("%s", "%s")',
          \a:opts['mapping'],
          \a:opts['engine'],
          \a:opts['input'])
  endif

  exe l:cmd
"}}}
endf

fun! ECY#engine#GetEngineInfo(engine_name)
"{{{
  for item in g:ECY_all_engines
    if item['engine_name'] == a:engine_name
      return item
    endif
  endfor
  return {}
"}}}
endf

fun! ECY#engine#Init()
  "{{{

  call s:InitUsableEngine()

  let g:ECY_show_switching_source_popup
        \= ECY#engine_config#GetEngineConfig('ECY', 'show_switching_engine_popup')

  let g:ECY_use_snippet
        \= get(g:,'ECY_use_snippet',"<C-b>")

  let g:ECY_use_path
        \= get(g:,'ECY_use_path',"/")

  call ECY#engine#MapEngine({
        \'engine': 'ECY_engines.snippet.ultisnips.ultisnips', 
        \'mapping': g:ECY_use_snippet})

  call ECY#engine#MapEngine({
        \'engine': 'ECY_engines.all.path', 
        \'input': '/', 
        \'mapping': g:ECY_use_path})

  exe 'nmap ' . g:ECY_show_switching_source_popup .
        \ ' :call ECY#engine#Do()<CR>'

  let g:ECY_file_type_using_path = g:ECY_base_dir.'/ECY_file_type_using.txt'

  let g:ECY_default_engine = 'ECY.engines.default_engine' " should change while python's changed

  let g:ECY_file_type_info2 = {}

  try
    let g:ECY_file_type_using = json_decode(readfile(g:ECY_file_type_using_path)[0])
  catch 
    call writefile(["{}"], g:ECY_file_type_using_path, 'b')
    let g:ECY_file_type_using = {}
  endtry

  augroup ECY_file_type_using
    autocmd!
    autocmd VimLeave    * call s:VimLeave()
    autocmd InsertLeave * call s:InsertLeave()
  augroup END
  "}}}
endf

fun! s:InitUsableEngine()
"{{{
  " let g:ECY_engine_list_file_path = g:ECY_engine_config_dir . '/engines.json'
  " let l:temp = readfile(g:ECY_engine_list_file_path)
  " let l:temp = json_decode(join(l:temp, "\n"))
  for item in keys(g:ECY_config)
    if has_key(g:ECY_config[item], 'filetype')
      let l:info = g:ECY_config[item]
      let l:info['engine_name'] = item
      call ECYAddEngine(l:info)
    endif
  endfor
"}}}
endf

fun! ECYAddEngine(info)
  "{{{
  if !exists('g:ECY_all_engines')
    let g:ECY_all_engines = []
  endif
  if has_key(a:info, 'disabled')
    if a:info['disabled']
      return
    endif
  endif
  call add(g:ECY_all_engines, a:info)
  "}}}
endf

fun! s:VimLeave()
  "{{{
  try
    for key in keys(g:ECY_file_type_info2)
      let l:temp = g:ECY_file_type_info2[key]
      let g:ECY_file_type_using[key] = l:temp['filetype_using']
    endfor
    call writefile([json_encode(g:ECY_file_type_using)], g:ECY_file_type_using_path, 'b')
  catch 
  endtry
  "}}}
endf

fun! ECY#engine#InitDefaultEngine(filetype)
  "{{{
  if !has_key(g:ECY_file_type_using, a:filetype)
    let g:ECY_file_type_using[a:filetype] = g:ECY_default_engine
  endif

  if !has_key(g:ECY_file_type_info2, a:filetype)
    let g:ECY_file_type_info2[a:filetype] = {
          \'available_sources': [], 
          \'filetype_using': g:ECY_file_type_using[a:filetype]
          \}
    for item in g:ECY_all_engines
      if !ECY#utils#IsInList(a:filetype, item['filetype']) && !ECY#utils#IsInList('all', item['filetype'])
        continue
      endif
      call add(g:ECY_file_type_info2[a:filetype]['available_sources'], item['engine_name'])
    endfor
  endif
  "}}}
endf

fun! ECY#engine#GetBufferEngineName()
  "{{{
  let l:filetype = ECY#utils#GetCurrentBufferFileType()
  call ECY#engine#InitDefaultEngine(l:filetype)
  return g:ECY_file_type_info2[l:filetype]['filetype_using']
  "}}}
endf

function! ECY#engine#IsInstalled(engine_name) abort
  if has_key(g:ECY_installer_config, a:engine_name)
    return v:true
  endif
  return v:false
endfunction

function! ECY#engine#UseSpecifyEngineOnce(engine_name, ...) abort
  "{{{
  let l:filetype = ECY#utils#GetCurrentBufferFileType()
  let l:current_engine_name = ECY#engine#GetBufferEngineName()
  if g:ECY_file_type_info2[l:filetype]['filetype_using'] != a:engine_name
    if !exists("g:ECY_file_type_info2[l:filetype]['last_engine_name']")
      let g:ECY_file_type_info2[l:filetype]['last_engine_name'] = l:current_engine_name
    endif
    let g:ECY_file_type_info2[l:filetype]['filetype_using'] = a:engine_name
    call ECY#rpc#rpc_event#OnBufferEnter()
  endif
  if a:0 == 0
    return ''
  else
    return a:1
  endif
  "}}}
endfunction

function! s:QFInstall(res) abort
  if a:res != {}
    exe "ECYInstallLS " . a:res['engine_name']
  endif
  return 1
endfunction

fun! ECY#engine#Show()
"{{{
  let l:to_show = []
  for item in g:ECY_all_engines
    let l:has_installer = has_key(item, 'installer_path')
    if !l:has_installer
      continue
    endif
    let l:is_installed = 
          \ECY#engine#IsInstalled(item['engine_name']) ? 'Installed' : 'NotInstalled'
    let l:is_install_color = ECY#engine#IsInstalled(item['engine_name']) ? 'Todo' : 'Error'
    if has_key(item, 'disabled') && item['disabled']
      continue
    endif
    call add(l:to_show, {'abbr': 
          \[{'value': l:is_installed, 'hl': l:is_install_color}, 
          \{'value': item['engine_name']}, 
          \],
          \'engine_name': item['engine_name']})
  endfor

  call ECY#qf#Open({'list': l:to_show, 'item': [
        \{'value': 'Installed?'}, 
        \{'value': 'Name'},
        \{'value': 'Name'},
        \]}, {'action': {'open#current_buffer': function('s:QFInstall')}})
"}}}
endf
