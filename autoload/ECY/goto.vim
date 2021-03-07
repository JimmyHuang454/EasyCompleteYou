fun! ECY#goto#Init()

endf

" {"jsonrpc":"2.0","result":[{"uri":"file:///C:/Users/qwer/Desktop/vimrc/myproject/test/go_hello_world/main.go","range":{"start":{"line":4,"character":1},"end":{"line":4,"character":6}}}],"id":306}
"
fun! ECY#goto#Do(res) abort
"{{{
  if type(a:res) == v:t_list && len(a:res) == 0
    return
  endif

  if type(a:res) == v:t_dict
    
  else
    let l:int = 0
    if len(a:res) != 1
      let s:show = ''
      let i = 1
      let l:uri = ''
      for item in a:res
        if has_key(item, 'uri')
          let l:uri = UriToPath(item['uri'])
        endif
        let s:show .= printf("%s. %s \n", string(i), l:uri)
        let i += 1
      endfor
      echo s:show
      let l:int = str2nr(input('Index: '))
      if l:int > len(a:res) || l:int == 0
        call ECY#utils#echo('Quited')
        return
      endif
    endif

    let l:seleted = a:res[l:int]
    if has_key(l:seleted, 'uri')
      call ECY#utils#echo(printf("Goto %s", UriToPath(l:seleted['uri'])))
    endif
  endif
"}}}
endf
