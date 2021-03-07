
fun! ECY#signature_help#Init() abort
"{{{
  let g:ECY_windows_are_showing['signature_help'] = -1
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
  if !g:ECY_enable_signature_help
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
  if g:has_floating_windows_support == 'vim'
    if g:ECY_windows_are_showing['signature_help'] != -1
      call popup_close(g:ECY_windows_are_showing['signature_help'])
    endif
  elseif g:has_floating_windows_support == 'neovim'
    " TODO
  else
    return
  endif
  let g:ECY_windows_are_showing['signature_help'] = -1
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

  let l:opts = {
      \ 'minwidth': g:ECY_preview_windows_size[0][0],
      \ 'maxwidth': g:ECY_preview_windows_size[0][1],
      \ 'minheight': g:ECY_preview_windows_size[1][0],
      \ 'maxheight': g:ECY_preview_windows_size[1][1],
      \ 'border': [],
      \ 'close': 'click',
      \ 'scrollbar': 1,
      \ 'firstline': 1,
      \ 'padding': [0,1,0,1],
      \ 'zindex': 2000,
      \'pos':'botleft',
      \'line':'cursor-1',
      \'col': 'cursor'}
  let l:nr = popup_create(l:to_show, l:opts)
  let g:ECY_windows_are_showing['signature_help'] = l:nr

  let l:activeSignature = 0
  if has_key(a:results, 'activeSignature')
    let l:activeSignature = a:results['activeSignature']
  endif

  let l:signatures = a:results['signatures'][l:activeSignature]
  let g:ECY_signature_help_activeParameter = s:Translate(string(l:activeSignature) . '.')

  let g:ECY_signature_help_activeSignature = ''
  if has_key(a:results, 'activeParameter') && len(l:signatures) != 0
    let l:parameters = l:signatures['parameters']
    let l:activeParameter = a:results['activeParameter']
    let g:ECY_signature_help_activeSignature = s:Translate(l:parameters[l:activeParameter]['label'])
  endif

  call setbufvar(winbufnr(l:nr), '&syntax', 'ECY_signature_help')
"}}}
endf
