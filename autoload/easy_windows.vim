let g:is_vim = !has('nvim')
let g:EW_info = {}
let s:windows_id = 0

let s:EW = {'pos': 'topleft', 
      \'title': '', 
      \'drag': 1, 
      \'syntax': '',
      \'moved_cb': '',
      \'closed_cb': '',
      \'hided_cb': '',
      \'showed_cb': '',
      \'created_cb': '',
      \'had_moved': 0,
      \'time': 0,
      \'zindex': 50,
      \'wrap': 1,
      \'firstline': 1,
      \'is_set_number': 0,
      \'is_hided': 0,
      \'is_created': 0,
      \}

function! easy_windows#new() abort
  let s:windows_id += 1
  let l:obj = deepcopy(s:EW)
  let g:EW_info[s:windows_id] = l:obj
  let l:obj['EW_id'] = s:windows_id
  return l:obj
endfunction

function! s:Callback(winid, CB, event_name) abort
  call CB(a:winid, a:event_name)
endfunction

" x - Screen line where to position the popup. 1-based.
" y - Screen column where to position the popup. 1-based.
" pos - defines what corner of the popup "line" and "col" are used for.
" title - Text to be displayed above the first item.
" wrap - TRUE to make the lines wrap.
" firstline - First buffer line to display.
" highlight - TRUE to make the lines wrap.
" borderchars - List with characters, defining the character to use for the top/right/bottom/left border.
" borderhighlight - List of highlight group names to use for the border.
" zindex - Priority for the popup, default 50.
" duration - Time in milliseconds after which the popup will close.
" number - Time in milliseconds after which the popup will close.
" syntax - 
" closed_cb 
" created_cb 
" hided_cb 
" showed_cb 
" moved_cb 
" key_bind - {'a':function('user_press_a') }
"
" maxheight
" minheight
" maxwidth
" minwidth
" padding_above
" padding_right
" padding_below
" padding_left
" border_above
" border_right
" border_below
" border_left
"
"
" scrollbar - show a scrollbar when the text doesn't fit. vim only.
" scrollbarhighlight - Highlight group name for the scrollbar. vim only.
" thumbhighlight - Highlight group name for the scrollbar thumb. vim only.
" drag - TRUE to allow the popup to be dragged with the mouse. vim only.
" close - When "button" an X is displayed in the top-right. vim only.
" resize - TRUE to allow the popup to be resized with the mouse. vim only.
function! s:EW._open(text_list, opts) abort
"{{{
  if type(a:text_list) != v:t_list && type(a:text_list) != v:t_string
    throw "Expect list or str."
  endif

  let l:text_list = a:text_list
  if type(a:text_list) == v:t_string
    let l:text_list = split(a:text_list, "\n")
  endif
  let self['text_list'] = l:text_list

  if g:is_vim
"{{{
    let l:real_opts = {}

    if has_key(a:opts, 'zindex')
      let l:real_opts['zindex'] = a:opts['zindex']
      let self['zindex'] = a:opts['zindex']
    else
      let l:real_opts['zindex'] = self['zindex']
    endif

    let self['title'] = ''
    if has_key(a:opts, 'title')
      let l:real_opts['title'] = a:opts['title']
      let self['title'] = a:opts['title']
    endif

    let self['duration'] = 0
    if has_key(a:opts, 'duration')
      let l:real_opts['time'] = a:opts['duration']
      let self['duration'] = a:opts['duration']
    endif

    let l:winid = popup_create(self['text_list'], l:real_opts)
"}}}
  else
    " TODO
  endif

  let self['winid'] = l:winid
  let self['is_created'] = 1
  let self['text_list'] = l:text_list

  call self._set_syntax('')
  if has_key(a:opts, 'syntax')
    call self._set_syntax(a:opts['syntax'])
  endif

  call self._unset_number()
  if has_key(a:opts, 'number') && a:opts['number']
    call self._set_number()
  endif

  call self._unset_wrap()
  if has_key(a:opts, 'wrap') && a:opts['wrap']
    call self._set_wrap()
  endif

  call self._exe_cmd('setl scrolloff=0', 0)
  call self._exe_cmd('setl signcolumn=no', 0)
  call self._exe_cmd('setl nocursorline', 0)
  call self._exe_cmd('setl nocursorcolumn', 0)
  call self._exe_cmd('setl nospell', 0)

  let self['real_opts'] = l:real_opts
"}}}
endfunction

function! s:EW._hide() abort
"{{{
  if !self['is_created'] || self['is_hided']
    return
  endif

  if g:is_vim
    call popup_hide(self['winid'])
  else
  endif
  let self['is_hided'] = 1
"}}}
endfunction

function! s:EW._show() abort
"{{{
  if !self['is_created'] || !self['is_hided']
    return
  endif

  if g:is_vim
    call popup_show(self['winid'])
  else
  endif
  let self['is_hided'] = 0
"}}}
endfunction

function! s:EW._close() abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call popup_close(self['winid'])
  else
  endif

  unlet g:EW_info[self['EW_id']]
"}}}
endfunction

function! s:EW._move(x, y) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call popup_move(self['winid'], a:opts)
  endif

"}}}
endfunction

function! s:EW._exe_cmd(cmd, is_silent) abort
  "{{{
  if !self['is_created']
    return
  endif

  let l:is_silent = a:is_silent
  let l:cmd = a:cmd

  if type(a:cmd) == v:t_list
    let l:cmd = join(a:cmd, "\n")
  endif

  if g:is_vim
    keepalt call win_execute(self['winid'], l:cmd, l:is_silent)
  else
    let current = nvim_get_current_win()
    keepalt call nvim_set_current_win(self['winid'])

    if l:is_silent == 0
      exec l:cmd
    else
      silent exec l:cmd
    endif

    keepalt call nvim_set_current_win(current)
  endif
  "}}}
endfunction

function! s:EW.__set_opts(opts_name, value) abort
  "{{{
  if !self['is_created']
    return
  endif

  let l:temp = {}
  let l:temp[a:opts_name] = a:value

  if g:is_vim
    call popup_setoptions(self['winid'], l:temp)
  else
    call nvim_win_set_config(self['winid'], l:temp)
  endif

  let self[a:opts_name] = a:value
  "}}}
endfunction

function! s:EW.__get_opts(opts_name) abort
  "{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    let l:opts = popup_getoptions(self['winid'])
  else
  endif

  if !has_key(l:opts, a:opts_name)
    return ''
  endif

  return l:opts[a:opts_name]
  "}}}
endfunction

function! s:EW._set_text(text_list) abort
"{{{
  if !self['is_created']
    return
  endif

  let l:text_list = a:text_list
  if type(l:text_list) == v:t_string
    let l:text_list = split(l:text_list)
  endif

  if type(l:text_list) != v:t_list
    return
  endif

  if g:is_vim
    call popup_settext(self['winid'], l:text_list)
  else
  endif

  let self['text_list'] = l:text_list
"}}}
endfunction

function! s:EW._set_line_text(line_text, linenr) abort
"{{{
  if !self['is_created']
    return
  endif

  if type(a:line_text) != v:t_string || len(self['text_list']) < a:linenr
    return
  endif

  if g:is_vim
    let l:bufnr = winbufnr(self['winid'])
    call setbufline(l:bufnr, a:linenr, a:line_text)
  endif

  call remove(self['text_list'], a:linenr - 1)
  call insert(self['text_list'], a:line_text, a:linenr - 1)
"}}}
endfunction

function! s:EW._get_text_line(linenr) abort
"{{{
  if !self['is_created']
    return
  endif

  if len(self['text_list']) < a:linenr || a:linenr >= 0
    return
  endif

  return self['text_list'][a:linenr - 1]
"}}}
endfunction

function! s:EW._set_syntax(syntax_name) abort
"{{{
  if !self['is_created']
    return
  endif

  call self._exe_cmd(printf('let &syn = "%s"', a:syntax_name), 0)
  let self['syntax'] = a:syntax_name
"}}}
endfunction

function! s:EW._set_number() abort
"{{{
  if !self['is_created']
    return
  endif

  call self._exe_cmd('setl number', 0)

  let self['is_set_number'] = 1
"}}}
endfunction

function! s:EW._unset_number() abort
"{{{
  if !self['is_created'] || !self['is_set_number']
    return
  endif

  call self._exe_cmd('setl nonumber', 0)

  let self['is_set_number'] = 0
"}}}
endfunction

function! s:EW._set_wrap() abort
"{{{
  if !self['is_created']
    return
  endif

  call self._exe_cmd('setl wrap', 0)

  let self['wrap'] = 1
  call self._get_height()
"}}}
endfunction

function! s:EW._unset_wrap() abort
"{{{
  if !self['is_created'] || !self['is_set_number']
    return
  endif

  call self._exe_cmd('setl wrap', 0)

  let self['wrap'] = 0
  call self._get_height()
"}}}
endfunction

function! s:EW._get_x() abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    return popup_getpos(self['winid'])['line']
  endif
"}}}
endfunction

function! s:EW._get_y() abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    return popup_getpos(self['winid'])['col']
  endif
"}}}
endfunction

function! s:EW._set_x(x) abort
"{{{
  if !self['is_created']
    return
  endif

  call self.__set_opts('line', a:x)
"}}}
endfunction

function! s:EW._set_y(y) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call self.__set_opts('col', a:y)
  else
    call self.__set_opts('col', a:y)
  endif
"}}}
endfunction

function! s:EW._set_width(width) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call self.__set_opts('minwidth', a:width)
  endif
"}}}
endfunction

function! s:EW._set_height(height) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call self.__set_opts('minheight', a:height)
  endif
"}}}
endfunction

function! s:EW._get_width() abort
"{{{
  if !self['is_created']
    return
  endif

  let l:width = 0
  for item in self['text_list']
    if len(item) < l:width
      continue
    endif
    let l:width = len(item)
  endfor

  let self['width'] = l:width

  return l:width
"}}}
endfunction

function! s:EW._get_height() abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    let l:first_line = line('w0', self['winid'])
    let l:last_line = line('w$', self['winid'])
    let l:height = l:last_line - l:first_line + 1
  else
  endif

  let self['height'] = l:height
"}}}
endfunction

function! s:Duration(EW_close, timer_id) abort
"{{{
  call a:EW_close()
"}}}
endfunction

function! s:EW._set_duration(milliseconds) abort
"{{{
  if !self['is_created']
    return
  endif

  let self['duration'] = a:milliseconds
  call timer_start(a:milliseconds, function('s:Duration', [self._close]))
"}}}
endfunction

let g:test = easy_windows#new()

call g:test._open(['import vim'], {})
call g:test._set_syntax('python')
call g:test._set_number()
call g:test._unset_number()
call g:test._set_text("print('hello1')\nprint('hello2')")
call g:test._set_line_text('print("hello3")', 1)
call g:test._set_line_text('print("hello4")', 2)
call g:test._set_duration(3000)
