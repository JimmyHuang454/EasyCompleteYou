
function! ECY#vim_lsp#main#Request() abort
"{{{
    let l:server_name = lsp#get_allowed_servers()[0]

      let l:context = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                    \'buffer_line': ECY#utils#GetCurrentLine(), 
                    \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                    \'time_stamp': reltimefloat(reltime()), 
                    \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                    \}

    " let l:server_name = context['server_name']

    let l:server = lsp#get_server_info(l:server_name)
    let l:position = ECY#utils#GetCurrentLineAndPosition()
    let l:position = {'line': l:position['line'], 'character': l:position['colum']}

    call lsp#send_request(l:server_name, {
        \ 'method': 'textDocument/completion',
        \ 'params': {
        \   'textDocument': lsp#get_text_document_identifier(),
        \   'position': l:position,
        \ },
        \ 'on_notification': function('s:handle_completion', [l:server, l:context]),
        \ })

"}}}
endfunction

function! s:handle_completion(server, context, data) abort
"{{{
    if lsp#client#is_error(a:data) || !has_key(a:data, 'response') || !has_key(a:data['response'], 'result')
        return
    endif
    let l:context = a:context

    " let l:context['server_info'] = a:server
    let l:context['response'] = a:data['response']
    let l:context['is_vim_lsp_callback'] = v:true

    call ECY#rpc#rpc_event#call({'event_name': 'OnCompletion', 'params': l:context})
"}}}
endfunction
