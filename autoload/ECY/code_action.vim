function! s:AskUser(results) abort
"{{{
  let s:show = ''
  let i = 0
  for item in a:results
    if has_key(item, 'disabled')
      continue
    endif

    let l:type = ''
    let l:kind = ''
    let l:title = ''

    if has_key(item, 'edit')
      let l:type .= 'Edit '
    endif

    if has_key(item, 'kind')
      let l:kind .= item['kind']
    endif

    if has_key(item, 'title')
      let l:title .= item['title']
    endif

    if has_key(item, 'command')
      if type(item['command']) == v:t_string
        " it is a command response.
        let l:type .= '& Commnand '
        let l:temp = item
        if has_key(l:temp, 'kind')
          let l:kind .= item['kind']
        endif
      else
        let l:type = 'Commnand '
        " code_action with command
        let l:temp = item['command']
      endif
      let l:cmd_name = l:temp['command']
      let l:cmd_args = get(l:temp, 'arguments', [])
    endif
    let i += 1
    let s:show .= printf("%s. %s | %s | %s \n", string(i), l:type, l:kind, l:title)
  endfor

  redraw!
  echo s:show
  let l:seleted_item = str2nr(input('Index: '))
  if l:seleted_item > len(a:results) || l:seleted_item == 0
    call ECY#utils#echo('Quited')
    return
  endif
  let l:seleted_item -= 1
  return l:seleted_item
"}}}
endfunction

fun! ECY#code_action#Do(context)
"{{{
  let s:results = a:context['result']
  if len(s:results) == 0
    call ECY#utils#echo('No action.')
    return
  endif

  let l:seleted_item = -1

  if get(g:, 'ECY_allow_preference', v:true)
    let i = 0
    for item in s:results
      if has_key(item, 'isPreferred') && item['isPreferred']
        let l:seleted_item = i
        break
      endif
      let i += 1
    endfor
  endif

  if l:seleted_item == -1
    let l:seleted_item = s:AskUser(s:results)
  else
    call ECY#utils#echo('Appled action.')
  endif

  if has_key(s:results[l:seleted_item], 'command') && 
        \has_key(s:results[l:seleted_item]['command'], 'arguments')
    
  endif

  let l:params = {'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange(),
        \'seleted_item': l:seleted_item, 'context': a:context}

  call ECY#rpc#rpc_event#call({'event_name': 'CodeActionCallback', 'params': l:params})
  "}}}
endf

