
fun! ECY#signature_help#Init() abort
"{{{
  let g:ECY_signature_help_activeParameter = ''
  let g:ECY_signature_help_activeSignature = ''

  let g:ECY_enable_signature_help
        \= get(g:,'ECY_enable_signature_help', v:true)

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

fun! s:Translate(origin) abort
"{{{
  let l:translated = ''
  let i = 0
  while i < len(a:origin)
    let item = a:origin[i]
    if item == '*'
      let l:translated .= "\\*"
    elseif item == '.'
      let l:translated .= "\\."
    elseif item == '+'
      let l:translated .= "\\+"
    elseif item == '{'
      let l:translated .= "\\{"
    elseif item == '}'
      let l:translated .= "\\}"
    elseif item == '['
      let l:translated .= "\\["
    elseif item == ']'
      let l:translated .= "\\]"
    else
      let l:translated .= item
    endif
    let i += 1
  endw
  return l:translated
"}}}
endf

fun! ECY#signature_help#Show(results) abort
"{{{
  if !g:ECY_enable_signature_help || mode() != 'i'
    return
  endif

  if g:has_floating_windows_support == 'vim'
    call s:Vim(a:results)
  elseif g:has_floating_windows_support == 'neovim'
    " TODO
  endif
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

  let l:to_show = []
  let i = 0
  for item in a:results['signatures']
    call add(l:to_show, printf("%s. %s", string(i), item['label']))
    let i += 1
  endfor

  let s:signature_help_obj = easy_windows#new()
  let l:temp = s:signature_help_obj._open(l:to_show, {
        \'anchor': 'SW',
        \'x': easy_windows#get_cursor_screen_x(),
        \'y': easy_windows#get_cursor_screen_y() - 1})

  call s:signature_help_obj._align_width()
  call s:signature_help_obj._align_height()

  let l:activeSignature = 0
  if has_key(a:results, 'activeSignature')
    let l:activeSignature = a:results['activeSignature']
  endif

  let l:signatures = a:results['signatures'][l:activeSignature]
  let g:ECY_signature_help_activeParameter = s:Translate(string(l:activeSignature) . '.')

  let g:ECY_signature_help_activeSignature = ''
  if has_key(a:results, 'activeParameter')
    let l:parameters = l:signatures['parameters']
    let l:activeParameter = a:results['activeParameter']
    try
      let l:activeParameter = l:parameters[l:activeParameter]
      let g:ECY_signature_help_activeSignature = s:Translate(l:activeParameter['label'])

      if has_key(l:activeParameter, 'documentation')
        call add(l:to_show, g:ECY_cut_line)
        call extend(l:to_show, l:activeParameter['documentation'])
      endif
    catch
    endtry
  endif
"}}}
endf
