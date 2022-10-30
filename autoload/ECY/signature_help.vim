
fun! ECY#signature_help#Init() abort
"{{{
  let g:ECY_signature_help_activeParameter = ''
  let g:ECY_signature_help_activeSignature = ''

  let g:ECY_enable_signature_help
        \= ECY#engine_config#GetEngineConfig('ECY', 'signature_help.enable')

  if g:ECY_enable_signature_help
    augroup ECY_signature_help
      autocmd!
      autocmd InsertLeave   * call s:OnInsertLeave()
    augroup END
  endif
"}}}
endf

fun! s:OnInsertLeave() abort
"{{{
  call ECY#signature_help#Close()
"}}}
endf

fun! ECY#signature_help#Show(results) abort
"{{{
  if !g:ECY_enable_signature_help || mode() != 'i'
    return
  endif

  call s:Vim(a:results)
  "}}}
endf

fun! ECY#signature_help#Close() abort
"{{{
  try
    call s:signature_help_obj._close()
  catch 
  endtry
"}}}
endf

fun! s:Vim(results) abort
"{{{
  call ECY#signature_help#Close()

  if len(a:results['signatures']) == 0
    return
  endif

  let l:to_show = a:results['to_show']

  let s:signature_help_obj = easy_windows#new()
  let l:temp = s:signature_help_obj._open(l:to_show, {
        \'anchor': 'SW',
        \'use_border': 1,
        \'x': easy_windows#get_cursor_screen_x(),
        \'y': easy_windows#get_cursor_screen_y() - 1})

  call s:signature_help_obj._align_width()
  call s:signature_help_obj._align_height()
  call s:signature_help_obj._set_syntax(&ft)

  let l:activeSignature = a:results['activeSignature']
  let l:signatures = a:results['signatures'][l:activeSignature]
  call s:signature_help_obj._add_match('ECY_document_link_style', [l:activeSignature + 1])

  let l:color = ECY#engine_config#GetEngineConfig('ECY', 'signature_help.activeParameter.color')

  if has_key(l:signatures, 'start')
    call s:signature_help_obj._add_match(l:color, [[l:activeSignature + 1, 
          \l:signatures['start'] + 1, l:signatures['str_len']]])
  endif
"}}}
endf
