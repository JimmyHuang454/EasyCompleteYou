function! s:AskUser(results) abort
"{{{
  let s:show = []
  let i = 0
  for item in a:results
    if has_key(item, 'disabled')
      continue
    endif

    let l:type = ''
    let l:kind = ''
    let l:kind_color = 'QuickFixLine'
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
        let l:kind_color = 'TabLine'
      else
        let l:type = 'Commnand '
        " code_action with command
        let l:temp = item['command']
      endif
      let l:cmd_name = l:temp['command']
      let l:cmd_args = get(l:temp, 'arguments', [])
    endif
    call add(s:show, {'abbr': 
          \[{'value': l:type}, 
          \{'value': l:kind, 'hl': l:kind_color}, {'value': l:title, 'hl': 'Comment'}],
          \'item_index': i})
    let i += 1
  endfor

  call ECY#qf#Open(
        \{'list': s:show, 'item': [
          \{'value': 'Type'}, {'value': 'Name'}, {'value': 'Title'}]}, 
        \{'action': {'open#current_buffer': function('s:DoAction')}})
"}}}
endfunction

function! s:DoAction(res) abort
"{{{
  if a:res != {}
    if has_key(a:res, 'command') && 
          \has_key(a:res['command'], 'arguments')
      " TODO
    endif

    let l:params = {'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange(),
          \'seleted_item': a:res['item_index'], 'context': g:ECY_code_action_context}

    call ECY#rpc#rpc_event#call({'event_name': 'CodeActionCallback', 'params': l:params})
    call ECY#utils#echo('Appled action.')
  endif
  return 1
"}}}
endfunction

fun! ECY#code_action#Do(context)
"{{{
  let g:ECY_code_action_context = a:context
  if len(g:ECY_code_action_context['result']) == 0
    call ECY#utils#echo('No action.')
    return
  endif

  let l:seleted_item = -1
  if get(g:, 'ECY_allow_preference', v:true)
    let i = 0
    for item in g:ECY_code_action_context['result']
      if has_key(item, 'isPreferred') && item['isPreferred']
        let l:seleted_item = i
        break
      endif
      let i += 1
    endfor
  endif

  if l:seleted_item == -1
    call s:AskUser(g:ECY_code_action_context['result'])
  else
    let l:temp = g:ECY_code_action_context['result'][l:seleted_item]
    let l:temp['item_index'] = l:seleted_item
    call s:DoAction(l:temp)
  endif
  "}}}
endf

fun! ECY#code_action#Undo()
"{{{
  call ECY#rpc#rpc_event#call({'event_name': 'UndoAction', 'params': {}})
"}}}
endf

fun! ECY#code_action#Undo_cb(res)
"{{{
  for item in keys(a:res)
    let l:buffer_nr = ECY#utils#IsFileOpenedInVim(item)
    if !l:buffer_nr " not in vim
      continue
    endif
    call ECY#utils#Replace(l:buffer_nr, 0, a:res[item]['new_text_len'] - 1, a:res[item]['undo_text'])
  endfor
"}}}
endf
