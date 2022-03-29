" TODO
"
fun! ECY#qf#Init()
  let g:ECY_qf_layout_style = 'button'
  let g:ECY_qf_layout = [float2nr(&columns * 0.5), float2nr(&lines * 0.6)]
  let g:ECY_qf_res = []
  let g:ECY_qf_key_map = { "<cr>": function('s:Open_current_buffer') }
endf

function! s:Open_current_buffer(index) abort
"{{{
  if a:index >= len(g:ECY_qf_res)
    return
  endif
  let l:res = g:ECY_qf_res[a:index]

  if !has_key(l:res, 'path')
    return
  endif

  if has_key(l:res, 'position')
    call ECY#utils#OpenFileAndMove(l:res['position']['line'],
          \l:res['position']['colum'], 
          \l:res['path'], '')
  else
    call ECY#utils#OpenFile(l:res['path'], '')
  endif
"}}}
endfunction

fun! s:FindFirstChar(strs, char) abort
  let i = 0
  while i < len(a:strs)
    if a:strs[i] == a:char
      return i
    endif
    let i += 1
  endw
  return -1
endf

func s:SortCompare(i1, i2)
  if a:i1['goal'] >= a:i2['goal']
    return 1
  endif
  return -1
endfunc

function! ECY#qf#FuzzyMatch(items, patten, filter_item) abort
"{{{
  let l:res = []
  for item in a:items
    if !has_key(item, a:filter_item)
      continue
    endif

    let l:abbr = item['abbr']
    let l:abbr_len = len(l:abbr)
    if l:abbr_len < len(a:patten) || l:abbr_len == 0
      continue
    endif

    let i = 0
    let j = 0
    let l:goal = 0
    let l:match_pos = []
    let l:is_matched = v:true
    while i < len(a:patten)
      if j == l:abbr_len
        let l:is_matched = v:false
        break
      endif
      let l:temp = s:FindFirstChar(l:abbr[j:], a:patten[i])
      if l:temp == -1
        let l:is_matched = v:false
        break
      endif
      let j += l:temp
      call add(l:match_pos, j)
      let i += 1
      let j += 1
      let l:goal += j
    endw

    let item['match_pos'] = l:match_pos
    let item['goal'] = l:goal
    if l:is_matched
      call add(l:res, item)
    endif
  endfor
  return sort(l:res, function('s:SortCompare'))
"}}}
endfunction

fun! s:UpdateRes() abort
  let l:res = ECY#qf#FuzzyMatch(g:ECY_qf_res, s:qf_input['input_value'], 'abbr')
  call s:RenderRes(l:res)
endf

fun! s:RenderRes(res) abort
"{{{
  let l:MAX_TO_SHOW = 18
  let l:MATCH_HL = 'ECY_floating_windows_normal_matched'
  let l:to_show = []
  let i = 0
  call s:qf_res._delete_match(l:MATCH_HL)
  for item in a:res
    if i == l:MAX_TO_SHOW
      break
    endif
    call add(l:to_show, item['abbr'])
    let i += 1
  endfor
  call s:qf_res._set_text(l:to_show)

  let i = 0
  for item in a:res
    if i == l:MAX_TO_SHOW
      break
    endif

    if !has_key(item, 'match_pos')
      continue
    endif
    
    for pos in item['match_pos']
      call s:qf_res._add_match(l:MATCH_HL, [[i + 1, pos + 1]])
    endfor
    let i += 1
  endfor
"}}}
endf

fun! ECY#qf#Close() abort
  call s:qf_res._close()
  return 1
endf

fun! ECY#qf#Open(lists, key_map) abort
"{{{
  let s:qf_res = easy_windows#new()
  call s:qf_res._open([], {'at_cursor': 0, 
        \'width': g:ECY_qf_layout[0],
        \'height': g:ECY_qf_layout[1],
        \'x': 1,
        \'y': 2,
        \'use_border': 0})

  let g:ECY_qf_res = a:lists
  call s:RenderRes(g:ECY_qf_res)
  let s:qf_input = easy_windows#new_input({'x': 1, 'y': 1, 
        \'height': 1,
        \'width': &columns,
        \'input_cb': function('s:UpdateRes'), 
        \'exit_cb': function('s:InputClose'),
        \'key_map': a:key_map,
        \'use_border': 0})
  call s:qf_input._input()
"}}}
endf

fun! ECY#qf#OpenExtern(lists, key_map) abort
  let g:ECY_qf_res = a:lists
  if exists('g:loaded_clap')
    exe "Clap ECY"
  elseif exists('g:leaderf_loaded')
    exe "Leaderf ECY"
  endif
endf

call ECY#qf#Init()
call ECY#qf#OpenExtern([{'abbr': 'test'}, {'abbr': 'ebct'}], {"\<C-j>": {'callback': function('ECY#qf#Close')}})
