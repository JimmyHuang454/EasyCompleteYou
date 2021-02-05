
function GetCurrentBufferPosition() abort
"{{{ utf-8]
  return { 'line': line('.') - 1, 'colum': col('.') - 1}
"}}}
endfunction

function GetCurrentLineAndPosition() abort
"{{{
  let l:temp = GetCurrentBufferPosition()
  let l:temp['line_content'] = getline(".")
  return l:temp
"}}}
endfunction

function GetCurrentLine() abort
"{{{
  return getline(".")
"}}}
endfunction

function GetCurrentBufferContent() abort " return list
"{{{
  return getbufline(bufnr(), 1, "$")
"}}}
endfunction

function DefineColor(name, colora) abort
"{{{
  if hlexists(a:name) 
    return
  endif
  exe 'hi '.a:name . ' '. a:colora
  try
    call prop_type_add(a:name, {'highlight': a:name}) " vim
  catch 
  endtry
"}}}
endfunction


function! IsInList(item, list) abort
"{{{
  let i = 0
  while i < len(a:list)
    if a:item == a:list[i]
      return v:true
    endif
    let i += 1
  endw
  return v:false
"}}}
endfunction
