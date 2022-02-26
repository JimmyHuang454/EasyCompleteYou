let g:is_vim = !has('nvim')
let g:has_nvim_0_6_0 = has('nvim-0.6.0')
let g:EW_info = {}
let s:close_after_cursor_moved = {}
let s:windows_id = 0

augroup EW_cursor
  autocmd!
  autocmd CursorMoved * call s:CloseAtCursor()
augroup END

let s:EW = {'anchor': 'NW', 
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

function! s:Callback(winid, CB, event_name) abort
  call CB(a:winid, a:event_name)
endfunction

function! s:CloseAtCursor() abort
  let l:current_line = line('.')
  for item in keys(s:close_after_cursor_moved)
    if s:close_after_cursor_moved[item]['showing_cursor'] == l:current_line
      continue
    endif
    call s:close_after_cursor_moved[item]._close()
    unlet s:close_after_cursor_moved[item]
  endfor
endfunction

" x - Screen line where to position the popup. 1-based.
" y - Screen column where to position the popup. 1-based.
" pos - defines what corner of the popup "line" and "col" are used for.
" title - Text to be displayed above the first item.
" wrap - TRUE to make the lines wrap.
" firstline - First buffer line to display.
" color - TRUE to make the lines wrap.
" borderchars - List with characters, defining the character to use for the top/right/bottom/left border.
" borderhighlight - List of color group names to use for the border.
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

  if self['is_term'] || self['is_input']
    return
  endif

  let l:text_list = a:text_list
  if type(a:text_list) == v:t_string
    let l:text_list = split(a:text_list, "\n")
  endif
  let self['text_list'] = l:text_list

  let l:real_opts = {}
  let self['real_opts'] = l:real_opts

  let self['x'] = has_key(a:opts, 'x') ? a:opts['x'] : 1
  let self['y'] = has_key(a:opts, 'y') ? a:opts['y'] : 1
  let self['title'] = has_key(a:opts, 'title') ? a:opts['title'] : ''
  let self['width'] = has_key(a:opts, 'width') ? a:opts['width'] : 10
  let self['height'] = has_key(a:opts, 'height') ? a:opts['height'] : 10
  let self['color'] = has_key(a:opts, 'color') ? a:opts['color'] : 'Pmenu'
  let self['anchor'] = has_key(a:opts, 'anchor') ? a:opts['anchor'] : 'NW'
  let self['is_hided'] = has_key(a:opts, 'is_hided') ? a:opts['is_hided'] : 0
  let self['use_border'] = has_key(a:opts, 'use_border') ? a:opts['use_border'] : 0
  if self['use_border']
    let self['border_char'] = 
          \has_key(a:opts, 'border_char') ? a:opts['border_char'] : ['│', '┌', '─', '┐', '└', '─', '┘', '│']
  endif

  if g:is_vim
"{{{
    if self['anchor'] == 'NW'
      let l:real_opts['pos'] = 'topleft'
    elseif self['anchor'] == 'NE'
      let l:real_opts['pos'] = 'topright'
    elseif self['anchor'] == 'SW'
      let l:real_opts['pos'] = 'botleft'
    elseif self['anchor'] == 'SE'
      let l:real_opts['pos'] = 'botright'
    endif

    let l:real_opts['fixed'] = 1
    let l:real_opts['hide'] = self['is_hided'] ? 1 : 0
    let l:real_opts['posinvert'] = 0
    let l:real_opts['col'] = self['x']
    let l:real_opts['line'] = self['y']
    let l:real_opts['minwidth'] = self['width']
    let l:real_opts['maxwidth'] = self['width']
    let l:real_opts['minheight'] = self['height']
    let l:real_opts['maxheight'] = self['height']
    let l:real_opts['title'] = self['title']

    if self['use_border']
      let l:real_opts['border'] = []

      let l:border = self['border_char']
      let l:real_opts['borderchars'] = [
            \l:border[2],
            \l:border[0],
            \l:border[5],
            \l:border[7],
            \l:border[1],
            \l:border[3],
            \l:border[6],
            \l:border[4],
            \]
    endif

    let l:winid = popup_create(self['text_list'], l:real_opts)
"}}}
  else
"{{{
    if self['anchor'] == 'NE'
      let self['x'] += 1
    elseif self['anchor'] == 'SW'
      let self['y'] += 1
    elseif self['anchor'] == 'SE'
      let self['x'] += 1
      let self['y'] += 1
    endif

    let self['x'] -= 1
    let self['y'] -= 1

    let l:bufnr = nvim_create_buf(v:false, v:true)
    call setbufvar(l:bufnr, '&buftype', 'nofile')
    call setbufvar(l:bufnr, '&bufhidden', 'hide')
    call setbufvar(l:bufnr, '&swapfile', 0)
    call setbufvar(l:bufnr, '&undolevels', -1)
    call setbufvar(l:bufnr, '&modifiable', 1) " neovim's bug
    call nvim_buf_set_lines(l:bufnr, 0, -1, v:true, l:text_list)
    let self['nvim_buf_id'] = l:bufnr

    let l:real_opts['anchor'] = self['anchor']
    let l:real_opts['col'] = self['x']
    let l:real_opts['row'] = self['y']
    let l:real_opts['width'] = self['width']
    let l:real_opts['height'] = self['height']

    let l:real_opts['relative'] = 'editor'
    let l:real_opts['style'] = 'minimal'

    if g:has_nvim_0_6_0
      let l:real_opts['noautocmd'] = 1

      if self['use_border']
        let l:border = self['border_char']
        let l:real_opts['border'] = [
              \[l:border[1], 'Pmenu'],
              \[l:border[2], 'Pmenu'],
              \[l:border[3], 'Pmenu'],
              \[l:border[0], 'Pmenu'],
              \[l:border[6], 'Pmenu'],
              \[l:border[5], 'Pmenu'],
              \[l:border[4], 'Pmenu'],
              \[l:border[7], 'Pmenu'],
              \]
      endif
    endif


    if !self['is_hided']
      let l:winid = self.__nvim_show()
    else
      let l:winid = -1
    endif
"}}}
  endif

  let self['winid'] = l:winid
  let self['is_created'] = 1
  let self['text_list'] = l:text_list
  let self['showing_cursor'] = line('.')
  call self._set_wincolor(self['color'])

  if has_key(a:opts, 'exit_cb')
    let self['exit_cb'] = a:opts['exit_cb']
  endif

  if has_key(a:opts, 'number') && a:opts['number']
    call self._set_number()
  else
    " call self._unset_number()
    let self['is_set_number'] = 0
  endif

  if has_key(a:opts, 'wrap') && a:opts['wrap']
    call self._set_wrap()
  else
    call self._unset_wrap() " init width and height
  endif

  if has_key(a:opts, 'firstline')
    call self._set_firstline(a:opts['firstline'])
  else
    " call self._set_firstline(1)
    let self['firstline'] = 1
  endif

  if has_key(a:opts, 'zindex')
    call self._set_zindex(a:opts['zindex'])
  else
    call self._set_zindex(500)
  endif

  " call self._exe_cmd('setl scrolloff=0', 0)
  " call self._exe_cmd('setl signcolumn=no', 0)
  " call self._exe_cmd('setl nocursorline', 0)
  " call self._exe_cmd('setl nocursorcolumn', 0)
  " call self._exe_cmd('setl nospell', 0)

  if has_key(a:opts, 'syntax')
    call self._set_syntax(a:opts['syntax'])
  else
    " call self._set_syntax('')
    let self['syntax'] = ''
  endif

  if has_key(a:opts, 'created_cb')
    let self['created_cb'] = a:opts['created_cb']
    call self['created_cb']()
  endif

  if has_key(a:opts, 'duration')
    call self._set_duration(a:opts['duration'])
  endif

  if has_key(a:opts, 'at_cursor') && a:opts['at_cursor']
    let s:close_after_cursor_moved[self['EW_id']] = self
  endif

  return l:winid
"}}}
endfunction

function! s:EW._input_cb() abort
  if has_key(self, 'input_cb')
    call self['input_cb']()
  endif
endfunction

function! s:EW._input() abort
"{{{
  if !self['is_input']
    return
  endif

  let self['is_input'] = 1
  let KEYS = "abcdefghijklmnopqrstuvwxyz"
  let KEYS .= "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  let KEYS .= "0123456789"
  let KEYS .= "~!@#$%^&*()_+\{\}|:\"\<\>\?"
  let KEYS .= "[]\;',./ "

  let l:key_map = self['key_map']

  let i = 0
  while i < len(KEYS)
    let item = KEYS[i]
    if !has_key(l:key_map, item)
      let l:key_map[item] = {'is_input_value': 1}
    endif
    let i += 1
  endw

	let [t_ve, guicursor] = [&t_ve, &guicursor]

  set t_ve=
  if guicursor != ''
    set guicursor=a:NONE
  en
  if !self['cmd_line']
    call self._set_text('|')
  endif
  while 1
    redraw
    let l:char_nr = getchar()
    let l:char = nr2char(l:char_nr)
    if  l:char_nr == "\<BS>"
      let l:char = "\<BS>"
    endif

    if l:char == "\<ESC>" || l:char == "\<C-c>"
      break
    endif

    if has_key(l:key_map, l:char) && has_key(l:key_map[l:char], 'is_input_value')
      let self['input_value'] .= l:char
    elseif l:char == "\<BS>"
      let l:value_len = len(self['input_value'])
      if l:value_len > 1
        let self['input_value'] = self['input_value'][0 : l:value_len - 2]
      else
        let self['input_value'] = ''
      endif
    elseif l:char == "\<C-u>"
      let self['input_value'] = ''
    elseif has_key(l:key_map, l:char) && has_key(l:key_map[l:char], 'callback')
      let l:res = l:key_map[l:char]['callback']()
      if l:res == 1
        break
      endif
    endif
    if self['cmd_line']
      echo self['input_value']
    else
      call self._set_text(self['input_value'] . '|')
    endif
    call self._input_cb()
  endw
  call self._close()
  let &t_ve = t_ve
  let &guicursor = guicursor
"}}}
endfunction

function! s:EW._open_term(opts) abort
  let self['is_term'] = 1
endfunction

function! s:EW._hide() abort
"{{{
  if !self['is_created'] || self['is_hided']
    return
  endif

  if g:is_vim
    call popup_hide(self['winid'])
  else
		call nvim_win_close(self['winid'], 1)
    let self['winid'] = -1
  endif
  let self['is_hided'] = 1
"}}}
endfunction

function! s:EW.__nvim_show() abort
"{{{
  let l:winid = nvim_open_win(self['nvim_buf_id'], 0, self['real_opts'])
  let self['winid'] = l:winid
  return l:winid
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
    let self['winid'] = self.__nvim_show()
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
    exe printf('bd! %s', self['nvim_buf_id'])
  endif

  if has_key(self, 'exit_cb')
    call self['exit_cb']()
  endif

  let self['is_created'] = 0
  let self['is_hided'] = 1
  unlet g:EW_info[self['EW_id']]
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
    let l:current_win = nvim_get_current_win()
    keepalt call nvim_set_current_win(self['winid'])

    if l:is_silent == 0
      exec l:cmd
    else
      silent exec l:cmd
    endif

    keepalt call nvim_set_current_win(l:current_win)
  endif
  "}}}
endfunction

function! s:EW._set_var(var_name, value) abort
  "{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call setbufvar(winbufnr(self['winid']), a:var_name, a:value)
  else
    call nvim_win_set_option(self['winid'], a:var_name, a:value)
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
    let l:text_list = split(l:text_list, "\n")
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

  call self._exe_cmd(printf("let &syntax = '%s'", a:syntax_name), 0)
  let self['syntax'] = a:syntax_name
"}}}
endfunction

function! s:EW._set_filetype(filetype) abort
"{{{
  if !self['is_created']
    return
  endif

  call self._exe_cmd(printf('let &ft = "%s"', a:filetype), 0)
  let self['filetype'] = a:syntax_name
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

function! s:EW._set_wincolor(color) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call self._exe_cmd(printf('let &wincolor="%s"', a:color), 0)
  else
    call nvim_win_set_option(self['winid'], 'winhl', printf('Normal:%s', a:color))
  endif
  let self['color'] = a:color
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

  let l:x = a:x

  if g:is_vim
    call self.__set_opts('col', l:x)
  else
    let l:x -= 1
    if self['anchor'] == 'NE'
      let l:x += 1
    endif
    call nvim_win_set_config(self['winid'], 
          \{'relative': 'editor', 'col': l:x, 'row': self._get_y()})
  endif
  let self['x'] = l:x
"}}}
endfunction

function! s:EW._set_y(y) abort
"{{{
  if !self['is_created']
    return
  endif

  let l:y = a:y

  if g:is_vim
    call self.__set_opts('line', l:y)
  else
    let l:y -= 1

    if self['anchor'] == 'SW'
      let l:y += 1
    elseif self['anchor'] == 'SE'
      let l:y += 1
    endif

    call nvim_win_set_config(self['winid'], 
          \{'relative': 'editor', 'row': l:y, 'col': self._get_x()})
  endif
  let self['y'] = l:y
"}}}
endfunction

function! s:EW._set_width(width) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call popup_move(self['winid'], {'minwidth': a:width, 'maxwidth': a:width})
  else
    call self.__set_opts('width', a:width)
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
    call popup_move(self['winid'], {'minheight': a:height, 'maxheight': a:height})
  else
    call self.__set_opts('height', a:height)
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

function! s:EW._set_minwidth(minwidth) abort
"{{{
  if !self['is_created']
    return
  endif

  let self['minwidth'] = a:minwidth
  call self._align_width()
"}}}
endfunction

function! s:EW._set_maxwidth(maxwidth) abort
"{{{
  if !self['is_created']
    return
  endif

  let self['maxwidth'] = a:minwidth
  call self._align_width()
"}}}
endfunction

function! s:EW._set_minheight(minheight) abort
"{{{
  if !self['is_created']
    return
  endif

  let self['minheight'] = a:minheight
  call self._align_height()
"}}}
endfunction

function! s:EW._set_maxheight(maxheight) abort
"{{{
  if !self['is_created']
    return
  endif

  let self['maxheight'] = a:maxheight
  call self._align_height()
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

function! s:EW._set_title(title) abort
"{{{
  if !self['is_created']
    return
  endif

  if g:is_vim
    call self.__set_opts('title', a:title)
  endif
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
    call self._exe_cmd('noautocmd normal! zt', 0)
  endif

  let self['firstline'] = a:line
"}}}
endfunction

function! s:EW._get_firstline() abort
"{{{
  if !self['is_created']
    return
  endif

  if !has_key(self, 'firstline')
    let self['firstline'] = 1
  endif

  return self['firstline']
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

  if self._get_firstline() == len(self['text_list'])
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

  if self._get_firstline() == 1
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

function! s:EW._get_showing_lines() abort
"{{{
  if !self['is_created']
    return
  endif

  let l:text_list = self['text_list']
  let l:first_line = self._get_firstline() - 1
  let l:last_line = l:first_line + self['height'] - 1

  return l:text_list[l:first_line: l:last_line]
"}}}
endfunction

function! s:EW._align_width() abort
"{{{
  if !self['is_created']
    return
  endif

  let l:showing_lines = self._get_showing_lines()

  let l:min = 0
  for item in l:showing_lines
    if len(item) <= l:min
      continue
    endif
    let l:min = len(item)
  endfor

  if has_key(self, 'minwidth')
    if l:min < self['minwidth']
      let l:min = self['minwidth']
    endif
  endif

  if has_key(self, 'maxwidth')
    if l:min > self['maxwidth']
      let l:min = self['maxwidth']
    endif
  endif

  if l:min > &columns
    let l:min = &columns
  endif

  call self._set_width(l:min)
"}}}
endfunction

function! s:EW._align_height() abort
"{{{
  if !self['is_created']
    return
  endif

  let l:min = len(self['text_list'])

  if has_key(self, 'minheight')
    if l:min < self['minheight']
      let l:min = self['minheight']
    endif
  endif

  if has_key(self, 'maxheight')
    if l:min > self['maxheight']
      let l:min = self['maxheight']
    endif
  endif

  if l:min > &lines
    let l:min = &lines
  endif

  call self._set_height(l:min)
"}}}
endfunction

function! easy_windows#hightlight(EW_id, hl_name, pos) abort
  let l:hl_id = matchaddpos(a:hl_name, a:pos)
  let g:EW_info[a:EW_id]['hi_list'][l:hl_id] = {'hl_name': a:hl_name, 'hl_id': l:hl_id}
endfunction

function! s:EW._add_match(hl_name, pos) abort
"{{{ 1-based.
  if !self['is_created']
    return
  endif

  if g:is_vim
    call self._exe_cmd(printf("call easy_windows#hightlight(%s, '%s', %s)", 
          \self['EW_id'], 
          \a:hl_name,
          \a:pos,
          \), 0)
  else
    " matchaddpos also works at nvim, but it's slow. So ...
    let l:hl_id = nvim_create_namespace('')
    for item in a:pos
      if type(item) == v:t_number
        call nvim_buf_add_highlight(self['nvim_buf_id'],
              \l:hl_id,
              \a:hl_name,
              \item[0] - 1,
              \0,
              \-1,
              \)
      elseif len(item) == 2
        call nvim_buf_add_highlight(self['nvim_buf_id'],
              \l:hl_id,
              \a:hl_name,
              \item[0] - 1,
              \item[1] - 1,
              \item[1],
              \)
      elseif len(item) == 3
        call nvim_buf_add_highlight(self['nvim_buf_id'],
              \l:hl_id,
              \a:hl_name,
              \item[0] - 1,
              \item[1] - 1,
              \item[1] + item[2] - 1,
              \)
      endif
    endfor
    let self['hi_list'][l:hl_id] = {'hl_name': a:hl_name, 'hl_id': l:hl_id}
  endif

"}}}
endfunction

function! s:EW._delete_match(hl_name) abort
"{{{
  if !self['is_created']
    return
  endif
  
  let l:hl = g:EW_info[self['EW_id']]['hi_list']

  for item in keys(l:hl)
    if l:hl[item]['hl_name'] != a:hl_name
      continue
    endif
    let l:hl_id = l:hl[item]['hl_id']
    if g:is_vim
      call self._exe_cmd(printf('call matchdelete(%s)', l:hl_id), 0)
    else
      call nvim_buf_clear_namespace(self['nvim_buf_id'], l:hl_id, 0, -1)
    endif
    unlet l:hl[item]
  endfor
"}}}
endfunction

function! easy_windows#new() abort
  let s:windows_id += 1
  let l:obj = deepcopy(s:EW)
  let g:EW_info[s:windows_id] = l:obj
  let l:obj['EW_id'] = s:windows_id
  let l:obj['hi_list'] = {}
  let l:obj['is_created'] = 0
  let l:obj['is_term'] = 0
  let l:obj['is_input'] = 0
  return l:obj
endfunction

function! easy_windows#new_input(opts) abort
  let l:obj = easy_windows#new()
  let l:obj['cmd_line'] = has_key(a:opts, 'cmd_line') ? a:opts['cmd_line'] : 0

  if !l:obj['cmd_line']
    call l:obj._open('', a:opts)
  endif

  let l:obj['is_input'] = 1
  let l:obj['input_value'] = ''
  let l:obj['key_map'] = has_key(a:opts, 'key_map') ? a:opts['key_map'] : {}
  if has_key(a:opts, 'input_cb')
    let l:obj['input_cb'] = a:opts['input_cb']
  endif
  return l:obj
endfunction

function! easy_windows#clear_all() abort
  for item in keys(g:EW_info)
    call g:EW_info[item]._close()
  endfor
endfunction

function! easy_windows#get_cursor_screen_y() abort
	let l:pos = win_screenpos('.')
  return l:pos[0] + winline() - 1
endfunction

function! easy_windows#get_cursor_screen_x() abort
	let l:pos = win_screenpos('.')
  return pos[1] + wincol() - 1
endfunction
