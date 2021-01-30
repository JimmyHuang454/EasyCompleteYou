set encoding=utf-8

set fileencoding=utf-8

let  g:current_dir = expand( '<sfile>:p:h' )
let  g:current_dir = tr(g:current_dir, '\', '/')

let  g:current_dir = g:current_dir .'/const.txt'
echo g:current_dir

let g:temp = {'$HOME': $HOME, '$VIMRUNTIME': $VIMRUNTIME, '$VIM': $VIM, '$XDG_CONFIG_HOME': $XDG_CONFIG_HOME}
let g:temp = json_encode(g:temp)

call writefile([g:temp], g:current_dir, 'w')

exe ":q!"
