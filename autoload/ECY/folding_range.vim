fun! ECY#folding_range#Init() abort
"{{{
"}}}
endf

fun! ECY#folding_range#Do(context) abort
"{{{
  let b:ECY_folding_context = a:context
  let l:seleting_folding_range = b:ECY_folding_context['seleting_folding_range']

  let l:item = b:ECY_folding_context['res'][l:seleting_folding_range]

  let l:startCharacter = 0
  if has_key(l:item, 'startCharacter')
    let l:startCharacter = l:item['startCharacter']
  endif

  let l:endLine = l:item['endLine'] + 1
  if has_key(l:item, 'endCharacter')
    let l:endCharacter = l:item['endCharacter']
  else
    let l:endCharacter = len(getbufline(bufnr(''), l:endLine)[0])
  endif
  let l:endCharacter += 1

  call ECY#utils#SeleteRange(
        \[l:item['startLine'] + 1, l:startCharacter + 1],
        \[l:endLine, l:endCharacter],
        \bufnr(''))
"}}}
endf
