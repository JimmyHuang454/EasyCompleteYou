let g:is_vim = !has('nvim')
let g:has_vim9 = has('patch-9.0.0')
let s:vim_mapped_type = {}

function! virtual_text#Add(text_list, start_pos, hl) abort
  if g:is_vim && !g:has_vim9
    return
  endif

  let l:text = join(a:text_list,'\n')

  if g:is_vim
    let l:type_info = ECY#utils#VimAddType(a:hl)
    call prop_add(a:start_pos['line'], 
          \a:start_pos['colum'],
          \{'text': l:text,
          \'id': l:type_info['hl_id'],
          \'type': l:type_info['type'],
          \})
  endif

endfunction

call virtual_text#Add(
      \['fuck'], {'line': 1,'colum': 1}, 'DiffAdd')
