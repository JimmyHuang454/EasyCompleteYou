let g:is_vim = !has('nvim')
let g:has_vim9 = has('patch-9.0.0')
let s:vim_mapped_type = {}
let s:vim_textprop_id = 0

function! virtual_text#Add(text_line, opts) abort"{{{
  if g:is_vim && !g:has_vim9
    return
  endif

  let l:start_pos = a:opts['start_pos'] " 0-based.
  let l:hl = a:opts['hl']

  if g:is_vim
    let l:type_info = s:VimAddType(l:hl)
    let l:id = prop_add(l:start_pos['line'] + 1, 
          \l:start_pos['colum'] + 1,
          \{'text': a:text_line,
          \'id': l:type_info['hl_id'],
          \'text_wrap': 'wrap',
          \'type': l:type_info['type'],
          \})
    return l:id
  else
  endif
endfunction"}}}

function! virtual_text#AddEOF(text_line, opts) abort"{{{
  if g:is_vim && !g:has_vim9
    return
  endif

  let l:hl = a:opts['hl']

  if g:is_vim
    let l:type_info = s:VimAddType(l:hl)
    let l:hl_id = prop_add(a:opts['start_pos']['line'] + 1, 
          \0,
          \{'text': a:text_line,
          \'id': l:type_info['hl_id'],
          \'text_align': 'after',
          \'text_wrap': 'wrap',
          \'type': l:type_info['type'],
          \})
  else
    let l:hl_id = nvim_create_namespace('')
    let l:buffer_id = bufnr('')
    call nvim_buf_set_extmark(l:buffer_id, 
          \l:hl_id, 
          \a:opts['start_pos']['line'], 
          \0,
          \{'virt_text': [[a:text_line, l:hl]], 
          \'virt_text_pos': 'eol'})
  endif
  return l:hl_id
endfunction"}}}

function! virtual_text#AddLine(text_line, opts) abort"{{{
  if g:is_vim && !g:has_vim9
    return
  endif

  let l:hl = a:opts['hl']

  if g:is_vim
    let l:type_info = s:VimAddType(l:hl)
    let l:lineNr = a:opts['start_pos']['line']
    let l:opts = a:opts
    let l:opts['start_pos'] = {'line': 1, 'colum': 1}
    if l:lineNr == 0
      " https://github.com/vim/vim/issues/11084
      call virtual_text#AddMiddle(a:text_line, l:opts)
      return
    endif

    let l:hl_id = prop_add(l:lineNr + 1, 
          \0,
          \{'text': a:text_line,
          \'id': l:type_info['hl_id'],
          \'text_align': 'below',
          \'text_wrap': 'wrap',
          \'type': l:type_info['type'],
          \})
  else
    let l:hl_id = nvim_create_namespace('')
    let l:buffer_id = bufnr('')
    call nvim_buf_set_extmark(l:buffer_id, 
          \l:hl_id, 
          \a:opts['start_pos']['line'], 
          \0,
          \{'virt_lines': [[[a:text_line, l:hl]]], 
          \'virt_lines_above': v:true})
  endif
  return l:hl_id
endfunction"}}}

function! virtual_text#Delete(id) abort"{{{
  if g:is_vim && !g:has_vim9
    return
  endif

  if g:is_vim
    try
      call prop_remove({'id': a:id})
    catch 
    endtry
  endif
endfunction"}}}

function! s:VimAddType(hl_name)
"{{{
  let s:vim_textprop_id += 1
  let l:hl_id = s:vim_textprop_id
  let l:type = printf('ECY_%s', a:hl_name . string(l:hl_id))
  call prop_type_add(l:type, {'highlight': a:hl_name})
  let s:vim_mapped_type[l:hl_id] = l:type
  return {'hl_id': l:hl_id, 'type': l:type}
"}}}
endfunction

function! virtual_text#Test() abort
  let l:opst = {'start_pos': {'line': 3,'colum': 1}, 'hl': 'Comment'}
  call virtual_text#AddLine('abc', l:opst)
endfunction

call virtual_text#Test()
