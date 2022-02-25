fun! ECY#qf#Init()
  let g:ECY_qf_layout_style = 'button'
  let g:ECY_qf_layout = [float2nr(&columns * 0.6), float2nr(&lines * 0.6)]
  let g:ECY_qf_layout = [10, 10]
  let s:res_list = []
endf

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
  let l:res = ECY#qf#FuzzyMatch(s:res_list, s:qf_input['input_value'], 'abbr')
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

fun! s:InputClose() abort
  call s:qf_res._close()
endf

fun! ECY#qf#Open(lists, key_map) abort
"{{{
  let s:qf_res = easy_windows#new()
  call s:qf_res._open([], {'at_cursor': 0, 
        \'width': g:ECY_qf_layout[0],
        \'height': g:ECY_qf_layout[1],
        \'use_border': 1})

  let s:res_list = a:lists
  call s:RenderRes(s:res_list)
  call s:qf_res._center_horizontal()
  call s:qf_res._center_vertical()
  let s:qf_input = easy_windows#new_input({'x': s:qf_res._get_x(), 'y': s:qf_res._get_y() - 3, 
        \'height': 1,
        \'width': 20,
        \'anchor': 'NW', 
        \'input_cb': function('s:UpdateRes'), 
        \'exit_cb': function('s:InputClose'),
        \'use_border': 1})
  call s:qf_input._input()
"}}}
endf

" echo ECY#qf#FuzzyMatch([{'abbr': 'test'}, {'abbr': 'ebct'}], 't', 'abbr')

" call ECY#qf#Init()
" call ECY#qf#Open([{'abbr': 'test'}, {'abbr': 'ebct'}], {})

