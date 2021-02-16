
function! s:ChooseSource_Echoing() abort
  "{{{ the versatitle way. could be used in many versions of vim or neovim.
  let l:filetype = &filetype
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
  let l:filetype = &filetype
  if !exists("g:ECY_file_type_info2[".string(l:filetype)."]")
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

fun! ECY#switch_engine#Do()
  "{{{
  let l:file_type = &filetype
  call s:InitDefaultEngine(l:file_type)

  if g:has_floating_windows_support == 'has_no'
    call s:ChooseSource_Echoing()
  elseif g:has_floating_windows_support == 'vim'
    call s:ChooseSource_Echoing()
    " call s:ChooseSource_vim()
  else
    call s:ChooseSource_neovim()
  endif
  doautocmd <nomodeline> EasyCompleteYou2 BufEnter " do cmd
  "}}}
endf

fun! ECY#switch_engine#Init()
  "{{{

  call s:InitUsableEngine()

  let g:ECY_show_switching_source_popup
        \= get(g:,'ECY_show_switching_source_popup','<Tab>')

  exe 'nmap ' . g:ECY_show_switching_source_popup .
        \ ' :call ECY#switch_engine#Do()<CR>'

  let g:ECY_config_path = g:ECY_base_dir.'/ECY_config.txt'

  let g:ECY_default_engine = 'ECY.engines.default_engine' " should change while python's changed

  let g:ECY_file_type_info2 = {}

  try
    let g:ECY_config = json_decode(readfile(g:ECY_config_path)[0])
  catch 
    let g:ECY_config = {}
  endtry

  augroup ECY_config
    autocmd!
    autocmd VimLeave  * call s:VimLeave()
  augroup END
  "}}}
endf

fun! s:InitUsableEngine()
  "{{{
  call ECYAddEngine({
        \'engine_name': 'ECY.engines.default_engine', 
        \'ability': [], 
        \'path': 'pip', 
        \'file_type':['all']
        \})

  call ECYAddEngine({
        \'engine_name': 'ECY_engines.cpp.clangd.clangd', 
        \'ability': [], 
        \'path': 'pip', 
        \'file_type':['c', 'cpp']
        \})

  call ECYAddEngine({
        \'engine_name': 'ECY_engines.python.jedi.jedi', 
        \'ability': [], 
        \'path': 'pip', 
        \'file_type':['python']
        \})

  call ECYAddEngine({
        \'engine_name': 'ECY_engines.golang.gopls.gopls', 
        \'ability': [], 
        \'path': 'pip', 
        \'file_type':['go']
        \})

  call ECYAddEngine({
        \'engine_name': 'ECY_engines.vim_lsp.vim_lsp', 
        \'ability': [], 
        \'path': 'pip', 
        \'file_type':['all']
        \})

  call ECYAddEngine({
        \'engine_name': 'ECY_engines.rust.rust_analyzer.rust_analyzer', 
        \'ability': [], 
        \'path': 'pip', 
        \'file_type':['rust']
        \})

  call ECYAddEngine({
        \'engine_name': 'ECY_engines.snippet.ultisnips.ultisnips', 
        \'ability': [], 
        \'path': 'pip', 
        \'file_type':['all']
        \})

  call ECYAddEngine({
        \'engine_name': 'ECY_engines.pygment.pygment', 
        \'ability': [], 
        \'path': 'pip', 
        \'file_type':['all']
        \})
  "}}}
endf

fun! ECYAddEngine(info)
  "{{{
  if !exists('g:ECY_all_buildin_engine')
    let g:ECY_all_buildin_engine = []
  endif
  call add(g:ECY_all_buildin_engine, a:info)
  "}}}
endf

fun! s:VimLeave()
  "{{{
  try
    for key in keys(g:ECY_file_type_info2)
      let l:temp = g:ECY_file_type_info2[key]
      let g:ECY_config[key] = l:temp['filetype_using']
    endfor
    call writefile([json_encode(g:ECY_config)], g:ECY_config_path, 'w')
  catch 
  endtry
  "}}}
endf

fun! s:InitDefaultEngine(file_type)
  "{{{
  if !has_key(g:ECY_config, a:file_type)
    let g:ECY_config[a:file_type] = g:ECY_default_engine
  endif

  if !has_key(g:ECY_file_type_info2, a:file_type)
    let g:ECY_file_type_info2[a:file_type] = {
          \'available_sources': [], 
          \'filetype_using': g:ECY_config[a:file_type]
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
  let l:file_type = &filetype
  call s:InitDefaultEngine(l:file_type)
  return g:ECY_file_type_info2[l:file_type]['filetype_using']
  "}}}
endf

function! ECY#switch_engine#UseSpecifyEngineOnce(engine_name) abort
  "{{{
  let l:file_type = &filetype
  let l:current_engine_name = ECY#switch_engine#GetBufferEngineName()
  let g:ECY_file_type_info2[l:file_type]['last_engine_name'] = l:current_engine_name
  let g:ECY_file_type_info2[l:file_type]['filetype_using'] = a:engine_name
  call ECY#rpc#rpc_event#OnCompletion()
  let g:ECY_file_type_info2[l:file_type]['filetype_using'] = l:current_engine_name
  "}}}
endfunction
