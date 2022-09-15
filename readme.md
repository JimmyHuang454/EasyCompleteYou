# Easily complete you

# "Keep It Simple, Stupid."

![image](https://github.com/JimmyHuang454/ECY_exe/raw/master/ECY_img/1.gif)

### Requires

1. Vim >= 8.2 or neovim >= 0.5.0.

(DO NOT need python)

### Install

Using some Plugin-manager like vim-plug or Vunble:
Put the line into your vimrc, then install it.

For vim-plug:

> Plug 'JimmyHuang454/EasyCompleteYou'

For user in China:

> Plug 'https://gitee.com/Jimmy_Huang/EasyCompleteYou2'

### Usage

You can use `:ECY` to list all commands. Finally, you should selete an engine that works at current filetype by `:ECYSwitchEngine`. Optionally, you need to install [ultisnips](https://github.com/SirVer/ultisnips) to enable Snippet feature.

### Available Engines

| Name                       | Programming Language | Installer | Link                                                                     |
| -------------------------- | :------------------: | --------: | ------------------------------------------------------------------------ |
| ECY.engines.default_engine |         All          |         - | -                                                                        |
| ECY_engines.cpp.clangd     |        C/C++         |       Yes | [clangd](https://github.com/clangd/clangd)                               |
| ECY_engines.python.jedi_ls |       Python3        |       Yes | [jedi language server](https://github.com/pappasam/jedi-language-server) |
| ECY_engines.html.html      |         HTML         |       Yes | -                                                                        |
| ECY_engines.viml.vimlsp    |         Viml         |       Yes | [viml language server](https://github.com/iamcco/vim-language-server)    |
| ECY_engines.html.vls       |         Vue          |       Yes | [vue language server](https://github.com/vuejs/vetur/tree/master/server) |
| ECY_engines.lua.lua        |         Lua          |       Yes | [lua language server](https://github.com/sumneko/lua-language-server)    |

### Add custom Language Server

Example:

```viml
let g:ECY_config = {
      \'name_of_the_LS':
      \{'cmd': 'jedi-language-server', 'filetype': ['python'], 
      \'initializationOptions': {'completion': {'enabled': v:true}}},
      \}
```


### Config

Example:

```viml
let g:ECY_config = {
      \'ECY_engines.python.jedi_ls':{'cmd': 'jedi-language-server'},
      \'ECY_engines.html.html': {'cmd': 'vscode-html-language-server'},
      \'ECY': {'completion': {'color': {'matched':'my_matched_color'}}},
      \}
```
