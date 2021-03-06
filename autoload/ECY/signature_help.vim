
fun! signature_help#Init() abort
"{{{
  let g:ECY_windows_are_showing['signature_help'] = -1
  augroup ECY_signature_help
    autocmd!
    autocmd TextChangedI  * call ECY#completion#Close()
    autocmd InsertLeave   * call s:OnInsertLeave()
  augroup END
"}}}
endf

fun! s:OnInsertLeave() abort
"{{{
  call signature_help#Close()
"}}}
endf

fun! signature_help#Show(results) abort
"{{{
  if g:has_floating_windows_support == 'vim'
    call s:Vim(a:results)
  elseif g:has_floating_windows_support == 'neovim'
    " TODO
  endif
  "}}}
endf

fun! signature_help#Close() abort
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
  call signature_help#Close()
  let l:to_show = []
  for item in a:results['signatures']
    call add(l:to_show, item['label'])
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
      \ 'zindex': 2000}
  let l:nr = popup_atcursor(l:to_show, l:opts)
  let g:ECY_windows_are_showing['signature_help'] = l:nr

  syn match ECY_signature_help_activeParameter  display ' '
  syn match ECY_signature_help_activeSignature  display ' '
  let l:activeSignature = 0

  if has_key(a:results, 'activeSignature')
    let l:activeSignature = a:results['activeSignature']
  endif

  let l:signatures = a:results['signatures'][l:activeSignature]
  let g:ECY_signature_help_activeParameter = l:signatures['label']

  let g:ECY_signature_help_activeSignature = ''
  if has_key(a:results, 'activeParameter') && len(l:signatures) != 0
    let l:parameters = l:signatures['parameters']
    let l:activeParameter = a:results['activeParameter']
    let g:ECY_signature_help_activeSignature = l:parameters[l:activeParameter]['label']
  endif

  call setbufvar(winbufnr(l:nr), '&syntax', 'ECY_signature_help')
"}}}
endf

call signature_help#Init()
call signature_help#Show({"activeParameter":0,"activeSignature":0,"signatures":[{"label":"sdf(int ab, char c) -> void","parameters":[{"label":"int ab"},{"label":"char c"}]}]})
