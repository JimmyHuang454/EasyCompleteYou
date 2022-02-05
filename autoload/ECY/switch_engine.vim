
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

fun! ECY#switch_engine#Do()
  "{{{
  let l:file_type = ECY#utils#GetCurrentBufferFileType()
  call ECY#switch_engine#InitDefaultEngine(l:file_type)
  let s:last_engine = ECY#switch_engine#GetBufferEngineName()

  " TODO
  call s:ChooseSource_Echoing()
  call s:ChooseSource_cb()
  "}}}
endf

fun! ECY#switch_engine#Set(file_type, engine_name)
  "{{{
  call ECY#switch_engine#InitDefaultEngine(a:file_type)
  let g:ECY_file_type_info2[a:file_type]['filetype_using'] = a:engine_name
  "}}}
endf

fun! s:InsertLeave()
"{{{
  let l:file_type = ECY#utils#GetCurrentBufferFileType()
  if !exists("g:ECY_file_type_info2[l:file_type]['last_engine_name']")
    return
  endif

  let g:ECY_file_type_info2[l:file_type]['filetype_using'] = 
        \g:ECY_file_type_info2[l:file_type]['last_engine_name']

  unlet g:ECY_file_type_info2[l:file_type]['last_engine_name']
  call ECY#rpc#rpc_event#OnBufferEnter()
"}}}
endf

fun! ECY#switch_engine#MapEngine(opts)
"{{{
  let l:cmd = printf(
        \'inoremap <expr> %s ECY#switch_engine#UseSpecifyEngineOnce("%s")',
        \a:opts['mapping'],
        \a:opts['engine'])

  if has_key(a:opts, 'input')
    let l:cmd = printf(
          \'inoremap <expr> %s ECY#switch_engine#UseSpecifyEngineOnce("%s", "%s")',
          \a:opts['mapping'],
          \a:opts['engine'],
          \a:opts['input'])
  endif

  exe l:cmd
"}}}
endf

fun! ECY#switch_engine#Init()
  "{{{

  call s:InitUsableEngine()

  let g:ECY_show_switching_source_popup
        \= get(g:,'ECY_show_switching_source_popup','<Tab>')

  let g:ECY_use_snippet
        \= get(g:,'ECY_use_snippet',"<C-b>")

  let g:ECY_use_path
        \= get(g:,'ECY_use_path',"/")

  call ECY#switch_engine#MapEngine({
        \'engine': 'ECY_engines.snippet.ultisnips.ultisnips', 
        \'mapping': g:ECY_use_snippet})

  call ECY#switch_engine#MapEngine({
        \'engine': 'ECY_engines.all.path', 
        \'input': '/', 
        \'mapping': g:ECY_use_path})

  exe 'nmap ' . g:ECY_show_switching_source_popup .
        \ ' :call ECY#switch_engine#Do()<CR>'

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
  let g:ECY_engine_list_file_path = g:ECY_engine_config_dir . '/engines.json'
  let l:temp = readfile(g:ECY_engine_list_file_path)
  let l:temp = json_decode(join(l:temp, "\n"))
  for item in l:temp['engines_list']
    call ECYAddEngine(item)
  endfor
"}}}
endf

fun! ECYAddEngine(info)
  "{{{
  if !exists('g:ECY_all_buildin_engine')
    let g:ECY_all_buildin_engine = []
  endif
  if has_key(a:info, 'disabled')
    if a:info['disabled']
      return
    endif
  endif
  call add(g:ECY_all_buildin_engine, a:info)
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

fun! ECY#switch_engine#InitDefaultEngine(file_type)
  "{{{
  if !has_key(g:ECY_file_type_using, a:file_type)
    let g:ECY_file_type_using[a:file_type] = g:ECY_default_engine
  endif

  if !has_key(g:ECY_file_type_info2, a:file_type)
    let g:ECY_file_type_info2[a:file_type] = {
          \'available_sources': [], 
          \'filetype_using': g:ECY_file_type_using[a:file_type]
          \}
    for item in g:ECY_all_buildin_engine
      if !IsInList(a:file_type, item['file_type']) && !IsInList('all', item['file_type'])
        continue
      endif
      call add(g:ECY_file_type_info2[a:file_type]['available_sources'], item['engine_name'])
    endfor
  endif
  "}}}
endf

fun! ECY#switch_engine#GetBufferEngineName()
  "{{{
  let l:file_type = ECY#utils#GetCurrentBufferFileType()
  call ECY#switch_engine#InitDefaultEngine(l:file_type)
  return g:ECY_file_type_info2[l:file_type]['filetype_using']
  "}}}
endf

function! ECY#switch_engine#UseSpecifyEngineOnce(engine_name, ...) abort
  "{{{
  let l:file_type = ECY#utils#GetCurrentBufferFileType()
  let l:current_engine_name = ECY#switch_engine#GetBufferEngineName()
  if g:ECY_file_type_info2[l:file_type]['filetype_using'] != a:engine_name
    if !exists("g:ECY_file_type_info2[l:file_type]['last_engine_name']")
      let g:ECY_file_type_info2[l:file_type]['last_engine_name'] = l:current_engine_name
    endif
    let g:ECY_file_type_info2[l:file_type]['filetype_using'] = a:engine_name
    call ECY#rpc#rpc_event#OnBufferEnter()
  endif
  if a:0 == 0
    return ''
  else
    return a:1
  endif
  "}}}
endfunction
