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

You can use `:ECY` to list all commands. Finally, you should selete an engine that works at current filetype by `:ECYSwitchEngine`

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

### Config

Example:

```viml
let g:ECY_config = {
      \'ECY_engines.python.jedi_ls':{'cmd': 'jedi-language-server'},
      \'ECY_engines.html.html': {'cmd': 'vscode-html-language-server'},
      \'ECY': {'completion': {'color': {'matched':'my_matched_color'}}},
      \}
```

| GLOBAL_SETTING                        |  Type   | Default Value | Des                    |
| ------------------------------------- | :-----: | ------------: | ---------------------- |
| lsp_formatting.tabSize                |   int   |             2 | LS init opts           |
| lsp_formatting.insertSpaces           | boolean |          True | LS init opts           |
| lsp_formatting.newlineStyle           | string  |
| LS init opts                          |
| lsp_formatting.trimTrailingWhitespace | boolean |          True | LS init opts           |
| lsp_formatting.trimFinalNewlines      | boolean |         False | LS init opts           |
| lsp_formatting.insertFinalNewline     | boolean |         False | LS init opts           |
| lsp.showMessage                       | boolean |          True | LS opts                |
| lsp_timeout                           |         |             5 | timeout after request. |

| ECY                                              |  Type   |             Default Value | Des                                              |
| ------------------------------------------------ | :-----: | ------------------------: | ------------------------------------------------ |
| completion.enable                                | boolean |                      True | Enable completion.                               |
| completion.triggering_length                     |   int   |                         1 | Minmun string length to trigger completion menu. |
| completion.expand_snippets_key                   | string  |                    \<CR\> | Key to trigger snippet if exists.                |
| completion.select_item                           |  list   |  ['\<tab\>', '\<s-tab\>'] | Seleting.                                        |
| diagnostics.update_diagnostics_in_insert_mode    | boolean |                     False | Is update diagnostics in insert mode?            |
| diagnostics.key_to_show_current_line_diagnostics | string  |                         H | Show info.                                       |
| diagnostics.key_to_show_next_diagnostics         | string  |                        [j | -                                                |
| diagnostics.text_highlight                       | string  | ECY_diagnostics_highlight | -                                                |
| diagnostics.erro_sign_highlight                  | string  |   ECY_erro_sign_highlight | -                                                |
| diagnostics.warn_sign_highlight                  | string  |   ECY_warn_sign_highlight | -                                                |
| diagnostics.enable                               | boolean |                      True | -                                                |
| use_floating_windows_to_be_popup_windows         | boolean |                      True | -                                                |
| file_type_blacklist                              |  list   |                   ['log'] | -                                                |
| disable_for_files_larger_than_kb                 |   int   |                      1024 | -                                                |
| document_link.enable                             | boolean |                     False | -                                                |
| document_link.disable_in_insert_mode             | boolean |                      True | -                                                |
| document_link.highlight_style                    | string  |   ECY_document_link_style | -                                                |
| goto.unload_buffer_after_goto                    | boolean |                      True | -                                                |
| semantic_tokens.enable                           | boolean |                      True | -                                                |
| semantic_tokens.disable_in_insert_mode           | boolean |                      True | -                                                |
| signature_help.enable                            | boolean |                      True | -                                                |
| preview_windows.enable                           | boolean |                      True | -                                                |
| show_switching_engine_popup                      | boolean |                   \<Tab\> | -                                                |
| ls_timeout                                       |   int   |                         3 | second                                           |
| symbols_color.Keyword                            | string  |                   Keyword | -                                                |
| symbols_color.Class                              | string  |                   Special | -                                                |
| completion.color.background                      | string  |                     Pmenu | -                                                |
| completion.color.seleted                         | string  |                  PmenuSel | -                                                |
| completion.color.seleted_matched                 | string  |                  PmenuSel | -                                                |
| completion.color.matched                         | string  |                   Keyword | -                                                |
| qf.colum_color                                   |  list   | ['DiffAdd', 'DiffChange'] | -                                                |

| ECY_engines.cpp.clangd                        |  Type   |                                                                                                               Default Value | Des                                                                                                                                                                                                   |
| --------------------------------------------- | :-----: | --------------------------------------------------------------------------------------------------------------------------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| cmd                                           | string  |                                                                                                                           - | cmd to start clangd.                                                                                                                                                                                  |
| cmd2                                          | string  |                                                                                                                      clangd | cmd to start clangd.                                                                                                                                                                                  |
| use_completion_cache                          | boolean |                                                                                                                       False | Is use completion cache?                                                                                                                                                                              |
| all_scopes_completion                         | boolean |                                                                                                                       False | If set to true, code completion will include index symbols that are not defined in the scopes (e.g. namespaces) visible from the code completion point. Such completions can insert scope qualifiers. |
| background_index                              | boolean |                                                                                                                        True | Index project code in the background and persist index on disk.                                                                                                                                       |
| clang_format_fallback_style                   | string  |                                                                                                                           - | clang-format style to apply by default when no .clang-format file is found.                                                                                                                           |
| pch_storage                                   | string  |                                                                                                                           - | Storing PCHs in memory increases memory usages, but may improve performance.                                                                                                                          |
| query_dirver                                  | string  |                                                                                                                           - | -                                                                                                                                                                                                     |
| initializationOptions.fallbackFlags           |  list   |                                                                                                                          [] | LS init opts                                                                                                                                                                                          |
| initializationOptions.compilationDatabasePath | string  |                                                                                                                        None | LS init opts                                                                                                                                                                                          |
| semantic_color                                |  list   | [[['comment'], 'Comment'], [['class', 'classScope', 'declaration'], 'SpellRare'], [['class', 'globalScope'], 'SpellLocal']] | -                                                                                                                                                                                                     |

| ECY_engines.html.vls |  Type  | Default Value | Des               |
| -------------------- | :----: | ------------: | ----------------- |
| cmd                  | string |             - | cmd to start vls. |
| cmd2                 | string |           vls | cmd to start vls. |

| ECY_engines.json.json |  Type  |              Default Value | Des                |
| --------------------- | :----: | -------------------------: | ------------------ |
| cmd                   | string |                          - | cmd to start json. |
| cmd2                  | string | vscode-json-languageserver | cmd to start json. |

| ECY_engines.lua.lua                 |  Type   |       Default Value | Des                               |
| ----------------------------------- | :-----: | ------------------: | --------------------------------- |
| cmd                                 | string  |                   - | cmd to start lua-language-server. |
| cmd2                                | string  | lua-language-server | cmd to start lua-language-server. |
| Lua.configuration.completion.enable | boolean |                True | cmd to start lua-language-server. |

| ECY_engines.html.html |  Type  |       Default Value | Des                    |
| --------------------- | :----: | ------------------: | ---------------------- |
| cmd                   | string |                   - | cmd to start html_lsp. |
| cmd2                  | string | html-languageserver | cmd to start html_lsp. |

| ECY_engines.golang.gopls |  Type  | Default Value | Des                 |
| ------------------------ | :----: | ------------: | ------------------- |
| cmd                      | string |             - | cmd to start gopls. |
| cmd2                     | string |         gopls | cmd to start gopls. |

| ECY_engines.python.jedi_ls                                   |  Type   |                                    Default Value | Des                |
| ------------------------------------------------------------ | :-----: | -----------------------------------------------: | ------------------ |
| cmd                                                          | string  |                                                - | cmd to start pyls. |
| cmd2                                                         | string  |                             jedi-language-server | cmd to start pyls. |
| initializationOptions.codeAction.nameExtractVariable         |  list   |                                  jls_extract_var | LS init opts       |
| initializationOptions.codeAction.nameExtractFunction         | string  |                                  jls_extract_var | LS init opts       |
| initializationOptions.diagnostics.enable                     | boolean |                                             True | LS init opts       |
| initializationOptions.diagnostics.didOpen                    | boolean |                                             True | LS init opts       |
| initializationOptions.diagnostics.didChange                  | boolean |                                             True | LS init opts       |
| initializationOptions.diagnostics.didSave                    | boolean |                                            False | LS init opts       |
| initializationOptions.completion.disableSnippets             | boolean |                                            False | LS init opts       |
| initializationOptions.completion.resolveEagerly              | boolean |                                            False | LS init opts       |
| initializationOptions.jediSettings.autoImportModules         |  list   |                                               [] | LS init opts       |
| initializationOptions.jediSettings.caseInsensitiveCompletion | boolean |                                             True | LS init opts       |
| initializationOptions.markupKindPreferred                    | string  |                                         markdown | LS init opts       |
| initializationOptions.workspace.extraPaths                   |  list   |                                               [] | LS init opts       |
| initializationOptions.workspace.symbols.ignoreFolders        |  list   | ['.nox', '.tox', '.venv', '__pycache__', 'venv'] | LS init opts       |
| initializationOptions.workspace.symbols.maxSymbols           |   int   |                                               20 | LS init opts       |

| ECY_engines.viml.vimlsp |  Type  |       Default Value | Des                  |
| ----------------------- | :----: | ------------------: | -------------------- |
| cmd                     | string |                   - | cmd to start vim LS. |
| cmd2                    | string | vim-language-server | cmd to start vim LS. |
