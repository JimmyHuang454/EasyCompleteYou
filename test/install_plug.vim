let s:repo_root = fnamemodify(expand('<sfile>'), ':h')
exe 'so ' . s:repo_root . '/install_plug.vim'

PlugInstall!
