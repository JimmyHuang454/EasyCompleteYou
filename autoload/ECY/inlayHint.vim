let s:render_inlay_hint = {}

fun! ECY#inlayHint#Get(...) abort
"{{{
  let l:engine_name = ECY2_main#GetEngineName(a:000)
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'GetInlayHint', 
        \'params': l:params, 
        \'engine_name': l:engine_name})
"}}}
endf

fun! ECY#inlayHint#Clear(path) abort
"{{{
  if !has_key(s:render_inlay_hint, a:path)
    return
  endif

  for item in s:render_inlay_hint[a:path]
    call ECY#virtual_text#Delete(item)
  endfor
  let s:render_inlay_hint[a:path] = []
"}}}
endf

fun! s:AddVirtualText(path, pos, text, hl) abort
"{{{
  let l:virtual_text_id = ECY#virtual_text#Add(a:text, {'start_pos': a:pos, 'hl': a:hl})
  call add(s:render_inlay_hint[a:path], l:virtual_text_id)
"}}}
endf

fun! ECY#inlayHint#Update(res) abort
"{{{
  if !g:has_virtual_text
    return
  endif

  let l:path = a:res['path']
  call ECY#inlayHint#Clear(l:path)
  let s:render_inlay_hint[l:path] = []

  for item in a:res['res']
    let l:pos = {'line': item['position']['line'], 'colum': item['position']['character']}

    if type(item['label']) == v:t_string
      call s:AddVirtualText(l:path, l:pos, item['label'], 'Comment')
    else
      for item2 in  item['label']
        call s:AddVirtualText(l:path, l:pos, item2['value'], 'Comment')
      endfor
    endif
  endfor
"}}}
endf
