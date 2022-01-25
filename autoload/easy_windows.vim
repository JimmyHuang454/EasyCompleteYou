let g:is_vim = !has('nvim')
let g:has_nvim_0_6_0 = has('nvim-0.6.0')
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

  let l:real_opts = {}
  if g:is_vim
"{{{
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
"{{{
    let l:bufnr = nvim_create_buf(v:false, v:true)
    call setbufvar(l:bufnr, '&buftype', 'nofile')
    call setbufvar(l:bufnr, '&bufhidden', 'hide')
    call setbufvar(l:bufnr, '&swapfile', 0)
    call setbufvar(l:bufnr, '&undolevels', -1)
    " neovim's bug
    call setbufvar(l:bufnr, '&modifiable', 1)
    call nvim_buf_set_lines(l:bufnr, 0, -1, v:true, l:text_list)

    let l:real_opts = {'relative': 'cursor', 'width': 30, 'height': 5, 'col': 0,
      \ 'row': 1, 'anchor': 'NW', 'style': 'minimal'}
    let l:winid = nvim_open_win(l:bufnr, 0, l:real_opts)
    let self['nvim_buf_id'] = l:bufnr
"}}}
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

  call self._set_firstline(1)
  if has_key(a:opts, 'firstline')
    call self._set_firstline(a:opts['firstline'])
  endif

  call self._set_zindex(50)
  if has_key(a:opts, 'zindex')
    call self._set_zindex(a:opts['zindex'])
  endif

  call self._set_x(1)
  if has_key(a:opts, 'x')
    call self._set_x(a:opts['x'])
  endif

  call self._set_y(1)
  if has_key(a:opts, 'y')
    call self._set_y(a:opts['y'])
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
    exe printf('close! %s', self['nvim_buf_id'])
  endif

  unlet g:EW_info[self['EW_id']]
  let self['is_created'] = 0
"}}}
endfunction

function! s:EW._move(x, y) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call popup_move(self['winid'], {'line': a:x, 'col': a:y})
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
    call nvim_buf_set_lines(self['nvim_buf_id'], 0, -1, v:true, l:text_list)
  endif

  let self['text_list'] = l:text_list
  call self._get_height()
  call self._get_width()
"}}}
endfunction

function! s:EW._set_line_text(line_text, linenr) abort
"{{{
  if !self['is_created']
    return
  endif

  if type(a:line_text) != v:t_string 
        \|| len(self['text_list']) < a:linenr || a:linenr <= 0
    return
  endif

  if g:is_vim
    let l:bufnr = winbufnr(self['winid'])
    call setbufline(l:bufnr, a:linenr, a:line_text)
  else
    call nvim_buf_set_lines(self['nvim_buf_id'], a:linenr - 1, a:linenr, v:true, [a:line_text])
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
  call self._get_width()
"}}}
endfunction

function! s:EW._unset_wrap() abort
"{{{
  if !self['is_created']
    return
  endif

  call self._exe_cmd('setl nowrap', 0)

  let self['wrap'] = 0
  call self._get_height()
  call self._get_width()
"}}}
endfunction

function! s:EW._get_x() abort
"{{{
  if !self['is_created']
    return
  endif

  if !has_key(self, 'x')
    return 1
  else
    return self['x']
  endif

"}}}
endfunction

function! s:EW._get_y() abort
"{{{
  if !self['is_created']
    return
  endif

  if !has_key(self, 'y')
    return 1
  else
    return self['y']
  endif

"}}}
endfunction

function! s:EW._set_x(x) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call self.__set_opts('col', a:x)
  else
    call nvim_win_set_config(self['winid'], 
          \{'relative': 'editor', 'col': a:x - 1, 'row': self._get_y() - 1 })
  endif
  let self['x'] = a:x
"}}}
endfunction

function! s:EW._set_y(y) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call self.__set_opts('line', a:y)
  else
    call nvim_win_set_config(self['winid'], 
          \{'relative': 'editor', 'row': a:y - 1, 'col': self._get_x() - 1 })
  endif
  let self['y'] = a:y
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

  let self['width'] = a:width
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

  let self['height'] = a:height
"}}}
endfunction

function! s:EW._get_width() abort
"{{{
  if !self['is_created']
    return
  endif

  let l:width = winwidth(self['winid'])
  let self['width'] = l:width
  return l:width
"}}}
endfunction

function! s:EW._get_height() abort
"{{{
  if !self['is_created']
    return
  endif

  let l:height = winheight(self['winid'])
  let self['height'] = l:height
  return l:height
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

function! s:EW._set_firstline(line) abort
"{{{
  if !self['is_created']
    return
  endif

  if a:line > len(self['text_list']) || a:line <= 0
    return
  endif

  if g:is_vim
    call self.__set_opts('firstline', a:line)
  else
		call nvim_win_set_cursor(self['winid'], [a:line, 0])
  endif

  let self['firstline'] = a:line
"}}}
endfunction

function! s:EW._set_zindex(zindex) abort
"{{{
  if !self['is_created']
    return
  endif

  let self['zindex'] = a:zindex

  if !g:has_nvim_0_6_0
    return
  endif
  call self.__set_opts('zindex', a:zindex)
"}}}
endfunction

function! s:EW._scroll_down() abort
"{{{
  if !self['is_created']
    return
  endif

  call self._set_firstline(self['firstline'] + 1)
"}}}
endfunction

function! s:EW._scroll_up() abort
"{{{
  if !self['is_created']
    return
  endif

  call self._set_firstline(self['firstline'] - 1)
"}}}
endfunction

function! s:EW._center_vertical() abort
"{{{
  if !self['is_created']
    return
  endif

  let l:vim_height = &lines
  let l:vim_middle = l:vim_height / 2
  let l:height = self._get_height()
  let l:middle = l:height / 2
  call self._set_y(l:vim_middle - l:middle)
"}}}
endfunction

function! s:EW._center_horizontal() abort
"{{{
  if !self['is_created']
    return
  endif

  let l:vim_width = &columns
  let l:vim_middle = l:vim_width / 2
  let l:height = self._get_width()
  let l:middle = l:height / 2
  call self._set_x(l:vim_middle - l:middle)
"}}}
endfunction

let g:test = easy_windows#new()

call g:test._open(['import vim'], {})
call g:test._set_syntax('python')
call g:test._set_number()
call g:test._unset_number()
call g:test._set_text("print('hello1')\nprint('hello2')\n3\n4")
call g:test._set_line_text('print("hello3")', 1)
call g:test._set_line_text('print("hello4")', 2)
call g:test._set_duration(10000)
call g:test._center_vertical()
call g:test._center_horizontal()
" call g:test._scroll_down()
