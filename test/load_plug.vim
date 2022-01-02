let s:repo_root = fnamemodify(expand('<sfile>'), ':h')
exe 'so ' . s:repo_root . '/plug.vim'

let s:all_plugs = {'EasyCompleteYou': 0, 'ultisnips': 0, 'vim-snippets': 0}

function! ECYInstalled(info) abort
  let s:all_plugs[a:info['name']] = 1
  for item in keys(s:all_plugs)
    if s:all_plugs[item] == 0
      return
    endif
  endfor
  cquit!
endfunction

call plug#begin(s:repo_root . '/test_plug_dir/')
  Plug 'JimmyHuang454/EasyCompleteYou', {'do': function('ECYInstalled')}
  Plug 'SirVer/ultisnips', {'do': function('ECYInstalled')}
  Plug 'honza/vim-snippets', {'do': function('ECYInstalled')}
call plug#end()

