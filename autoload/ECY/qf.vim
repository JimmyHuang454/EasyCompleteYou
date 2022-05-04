fun! ECY#qf#Init()
  let g:ECY_qf_layout_style = 'button'
  let g:ECY_qf_layout = [float2nr(&columns * 0.5), &lines]
  let g:ECY_qf_res = []
  let g:ECY_qf_res_external = []
  let s:fz_res = []
  let g:ECY_action_map = {
        \'open#current_buffer': "\<Cr>", 
        \'open#new_tab': "\<C-t>",
        \'open#vertically': "\<C-v>",
        \'open#horizontally': "\<C-x>",
        \'select#next': "\<C-j>",
        \'select#prev': "\<C-k>",
        \}

  let g:ECY_action_fuc = {
        \'open#current_buffer': function('s:Open_current_buffer'),
        \'open#new_tab': function('s:Open_new_tab'),
        \'open#vertically': function('s:Open_vertically'),
        \'open#horizontally': function('s:Open_horizontally'),
        \'select#next': function('s:NextItem'),
        \'select#prev': function('s:PrevItem'),
        \}

  let s:selecting_item_index = 0
  let s:MAX_TO_SHOW = 18

  let s:qf_preview = easy_windows#new()
endf

function! s:GetRes() abort
"{{{
  let l:res = {}
  if s:selecting_item_index < len(s:fz_res)
    let l:res = s:fz_res[s:selecting_item_index]
  endif
  return l:res
"}}}
endfunction

function! s:Gerneral(CB) abort
"{{{
  return a:CB(s:GetRes())
"}}}
endfunction

"{{{actions
function! ECY#qf#OpenBuffer(res, windows_style) abort
"{{{
  if has_key(a:res, 'path')
    if has_key(a:res, 'position')
      call ECY#utils#OpenFileAndMove(a:res['position']['line'],
            \a:res['position']['colum'], 
            \a:res['path'], a:windows_style)
    else
      call ECY#utils#OpenFile(a:res['path'], a:windows_style)
    endif
  endif
  return 1
"}}}
endfunction

function! s:Open_current_buffer(res) abort
"{{{
  return ECY#qf#OpenBuffer(a:res, '')
"}}}
endfunction

function! s:Open_vertically(res) abort
"{{{
  return ECY#qf#OpenBuffer(a:res, 'v')
"}}}
endfunction

function! s:Open_horizontally(res) abort
"{{{
  return ECY#qf#OpenBuffer(a:res, 'h')
"}}}
endfunction

function! s:Open_new_tab(res) abort
"{{{
  return ECY#qf#OpenBuffer(a:res, 't')
"}}}
endfunction

fun! s:NextItem(...) abort
  let s:selecting_item_index += 1
  let s:selecting_item_index %= (s:MAX_TO_SHOW - 1)
endf

fun! s:PrevItem(...) abort
  let s:selecting_item_index -= 1
  let s:selecting_item_index %= (s:MAX_TO_SHOW - 1)
endf

"}}}

"{{{FuzzyMatch
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
endfunction"}}}

fun! s:UpdateRes() abort
  let s:fz_res = ECY#qf#FuzzyMatch(g:ECY_qf_res, s:qf_input['input_value'], 'abbr')
  call s:RenderRes(s:fz_res)
  call s:UpdatePreview()
endf

fun! s:UpdatePreview() abort
"{{{
  let l:res = s:GetRes()
  call s:qf_preview._close()
  if l:res != {} && has_key(l:res, 'path')
    let l:path = l:res['path']
    let l:content = ECY#utils#GetPathContent(l:path)
    if l:content == []
      return
    endif

    let s:qf_preview = easy_windows#new()
    call s:qf_preview._open(l:content, {'x': g:ECY_qf_layout[0] + 1, 'y': 1, 
          \'height': g:ECY_qf_layout[1],
          \'width': g:ECY_qf_layout[0] - 3,
          \'use_border': 1})
    if has_key(l:res, 'position')
      call s:qf_preview._set_firstline(l:res['position']['line'])
    endif
  endif
"}}}
endf

fun! s:RenderRes(fz_res) abort
"{{{
  let l:MATCH_HL = 'ECY_floating_windows_normal_matched'
  let l:to_show = []
  if len(a:fz_res) <= s:selecting_item_index || s:selecting_item_index < 0
    let s:selecting_item_index = 0
  endif
  let i = 0
  call s:qf_res._delete_match(l:MATCH_HL)
  for item in a:fz_res
    if i == s:MAX_TO_SHOW
      break
    endif
    let l:prev_mark = '  '
    if i == s:selecting_item_index
      let l:prev_mark = '> '
    endif
    call add(l:to_show, l:prev_mark . item['abbr'])
    let i += 1
  endfor
  call s:qf_res._set_text(l:to_show)

  let i = 0
  for item in a:fz_res
    if i == s:MAX_TO_SHOW
      break
    endif

    if !has_key(item, 'match_pos')
      continue
    endif
    
    for pos in item['match_pos']
      call s:qf_res._add_match(l:MATCH_HL, [[i + 1, pos + 3]])
    endfor
    let i += 1
  endfor
"}}}
endf

fun! ECY#qf#Close() abort
  call s:qf_res._close()
  call s:qf_preview._close()
  return 1
endf

fun! ECY#qf#Open(lists, opts) abort
"{{{
  let s:selecting_item_index = 0
  let s:qf_res = easy_windows#new()
  call s:qf_res._open([], {'at_cursor': 0, 
        \'width': g:ECY_qf_layout[0],
        \'height': g:ECY_qf_layout[1],
        \'x': 1,
        \'y': 2,
        \'use_border': 0})

  let g:ECY_qf_res = a:lists
  let s:fz_res = g:ECY_qf_res
  call s:RenderRes(g:ECY_qf_res)

  let l:temp_map = {}
  for item in keys(g:ECY_action_map)
    let l:temp = {}
    if has_key(a:opts, 'key_map') && has_key(a:opts['key_map'], item)
      let l:temp['callback'] = function('s:Gerneral', [a:opts['key_map'][item]])
    else
      let l:temp['callback'] = function('s:Gerneral', [g:ECY_action_fuc[item]])
    endif
    let l:temp_map[g:ECY_action_map[item]] = l:temp
  endfor

  let s:qf_input = easy_windows#new_input({'x': 1, 'y': 1, 
        \'height': 1,
        \'width': g:ECY_qf_layout[0],
        \'input_cb': function('s:UpdateRes'), 
        \'exit_cb': function('ECY#qf#Close'),
        \'key_map': l:temp_map,
        \'use_border': 0})
  call s:qf_input._input()
"}}}
endf

fun! ECY#qf#OpenExternal(lists, opts) abort
  let g:ECY_qf_res = a:lists
  if exists('g:leaderf_loaded')
    call g:LeaderfECY_Start()
  elseif exists('g:loaded_clap')
    execute "Clap ECY"
  else
    call ECY#qf#Open(g:ECY_qf_res, a:opts)
  endif
endf

fun! ECY#qf#Test() abort
  let l:map = {}
  call ECY#qf#OpenExternal([{'abbr': 'test', 'path': 'C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou2/autoload/easy_windows.vim'}, {'abbr': 'ebct', 'path': 'C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou2/after/plugin/clap.vim'}], {})
endf

call ECY#qf#Init()
