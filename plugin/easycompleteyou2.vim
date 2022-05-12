" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

let g:ECY_starttime = reltimefloat(reltime())

function! s:restore_cpo()
  let g:loaded_ECY2 = v:true
  let &cpo = s:save_cpo
  unlet s:save_cpo
endfunction

if !exists("g:os")
  if has("win64") || has("win32") || has("win16")
    let g:os = "Windows"
  else
    let g:os = substitute(system('uname'), '\n', '', '')
    if g:os == 'Darwin'
      let g:os = 'macOS'
    else
      let g:os = 'Linux'
    endif
  endif
endif

let g:is_vim = !has('nvim')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                check require                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_ECY2')
  finish
elseif &encoding !~? 'utf-\?8'
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires UTF-8 encoding. " .
        \ "Put the line 'set encoding=utf-8' into your vimrc." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif ( g:is_vim && !has('patch-8.1.1578') ) || 
      \ (!g:is_vim && !has('nvim-0.5.0'))
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires NeoVim >= 0.5.0 ".
        \ "or Vim >= 8.2." |
        \ echohl None
  call s:restore_cpo()
  finish
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 init vars                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" must put these outside a function
let g:ECY_base_dir = expand('<sfile>:p:h:h')
let g:ECY_base_dir = tr(g:ECY_base_dir, '\', '/')

let g:ECY_python_script_folder_dir = g:ECY_base_dir . '/python'
let g:ECY_client_main_path = g:ECY_python_script_folder_dir . '/client_main.py'
let g:ECY_source_folder_dir = g:ECY_base_dir . '/engines'
let g:ECY_client_main_path = printf("%s/ECY_%s.exe", g:ECY_python_script_folder_dir, g:os)

function! s:Goto(types, is_preview) abort
"{{{
  if a:types == 'definitions' || a:types == 'definition'
    call ECY2_main#Goto('', 'GotoDefinition', a:is_preview)
  elseif a:types == 'declaration'
    call ECY2_main#Goto('', 'GotoDeclaration', a:is_preview)
  elseif a:types == 'implementation'
    call ECY2_main#Goto('', 'GotoImplementation', a:is_preview)
  elseif a:types == 'typeDefinition' || a:types == 'type_definition'
    call ECY2_main#Goto('', 'GotoTypeDefinition', a:is_preview)
  else
    echo a:types
  endif
"}}}
endfunction

"{{{
function! s:DoCommand(res) abort
  if a:res != {}
    exe a:res['cmd']
  endif
  return 1
endfunction

function! s:AllCommand() abort
  let g:ECY_cmd_list = {
        \'ECYHover': {'des': 'Provide by LS.'},
        \'ECYFormat': {'des': 'Provide by LS.'},
        \'ECYRename': {'des': 'Provide by LS.'},
        \'ECYSymbol': {'des': 'Provide by LS.'},
        \'ECYDocSymbol': {'des': 'Provide by LS.'},
        \'ECYSeleteRange': {'des': 'Provide by LS.'},
        \'ECYSeleteRangeParent': {'des': 'Provide by LS.'},
        \'ECYFindReference': {'des': 'Provide by LS.'},
        \'ECYDiagnostics': {'des': 'Provide by LS.'},
        \}
  let l:res = []
  for item in keys(g:ECY_cmd_list)
    call add(l:res, {'abbr': [item, item['des']], 'cmd': item})
  endfor
  call ECY#qf#Open(l:res, {'action': {'open#current_buffer': function('s:DoCommand')}})
endfunction
"}}}

vmap <C-h> <ESC>:call ECY2_main#DoCodeAction({'range_type': 'selected_range'})<CR>
nmap <C-h> :call ECY2_main#DoCodeAction({'range_type': 'current_line'})<CR>

nmap vae :ECYSeleteRange<CR>
nmap var :ECYSeleteRangeParent<CR>
nmap vat :ECYSeleteRangeChild<CR>

vmap ae <ESC>:ECYSeleteRangeParent<CR>
vmap ar <ESC>:ECYSeleteRangeParent<CR>
vmap at <ESC>:ECYSeleteRangeChild<CR>

command! -nargs=0 ECY                  call s:AllCommand()
command! -nargs=* ECYGoto              call s:Goto(<q-args>, 0)
command! -nargs=* ECYGotoP             call s:Goto(<q-args>, 1)
command! -nargs=0 ECYHover             call ECY2_main#Hover()
command! -nargs=0 ECYFormat            call ECY2_main#Format()
command! -nargs=0 ECYRename            call ECY2_main#Rename()
command! -nargs=0 ECYReStart           call ECY2_main#ReStart()
command! -nargs=* ECYInstallLS         call ECY2_main#InstallLS(<q-args>)
command! -nargs=* ECYUnInstallLS       call ECY2_main#UnInstallLS(<q-args>)
command! -nargs=0 ECYDocSymbol         call ECY2_main#GetDocumentSymbol()
command! -nargs=0 ECYDocSymbols        call ECY2_main#GetDocumentSymbol()
command! -nargs=0 ECYSymbol            call ECY2_main#GetWorkSpaceSymbol()
command! -nargs=0 ECYSymbols           call ECY2_main#GetWorkSpaceSymbol()
command! -nargs=0 ECYSeleteRange       call ECY2_main#SeleteRange()
command! -nargs=0 ECYSeleteRangeParent call ECY#selete_range#Parent()
command! -nargs=0 ECYSeleteRangeChild  call ECY#selete_range#Child()
command! -nargs=0 ECYFoldLine          call ECY2_main#FoldingRangeCurrentLine()
command! -nargs=0 ECYFold              call ECY2_main#FoldingRange()
command! -nargs=0 ECYFindReference     call ECY2_main#FindReferences()
command! -nargs=0 ECYDiagnostics       call ECY#diagnostics#ShowSelecting(0)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Go                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ECY_preview_windows_size = 
      \get(g:,'ECY_preview_windows_size',[[30, 70], [2, 14]])

call ECY#engine_config#Init()
call ECY#completion#Init()
call ECY2_main#Init()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    end                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ECY_endtime = reltimefloat(reltime())
let g:ECY_start_time = g:ECY_endtime - g:ECY_starttime

call s:restore_cpo()
