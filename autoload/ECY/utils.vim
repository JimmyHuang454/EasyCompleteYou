
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
