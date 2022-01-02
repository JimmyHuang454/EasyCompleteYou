let s:repo_root = fnamemodify(expand('<sfile>'), ':h')
exe 'so ' . s:repo_root . '/load_plug.vim'

PlugInstall!
