"{{{

fun! s:RPC_Events_OnBufNewFile() " starting to edit a file that doesn't exist
    call RPCEventsAll('BufNewFile')
endf

fun! s:RPC_Events_OnBufReadPre() " starting to edit a new buffer, before reading the file
    call RPCEventsAll('BufReadPre')
endf

fun! s:RPC_Events_OnBufRead() " starting to edit a new buffer, after reading the file
    call RPCEventsAll('BufRead')
endf

fun! s:RPC_Events_OnBufReadPost() " starting to edit a new buffer, after reading the file
    call RPCEventsAll('BufReadPost')
endf

fun! s:RPC_Events_OnBufReadCmd() " before starting to edit a new buffer |Cmd-event|
    call RPCEventsAll('BufReadCmd')
endf

fun! s:RPC_Events_OnFileReadPre() " before reading a file with a ':read' command
    call RPCEventsAll('FileReadPre')
endf

fun! s:RPC_Events_OnFileReadPost() " after reading a file with a ':read' command
    call RPCEventsAll('FileReadPost')
endf

fun! s:RPC_Events_OnFileReadCmd() " before reading a file with a ':read' command |Cmd-event|
    call RPCEventsAll('FileReadCmd')
endf

fun! s:RPC_Events_OnFilterReadPre() " before reading a file from a filter command
    call RPCEventsAll('FilterReadPre')
endf

fun! s:RPC_Events_OnFilterReadPost() " after reading a file from a filter command
    call RPCEventsAll('FilterReadPost')
endf

fun! s:RPC_Events_OnStdinReadPre() " before reading from stdin into the buffer
    call RPCEventsAll('StdinReadPre')
endf

fun! s:RPC_Events_OnStdinReadPost() " After reading from the stdin into the buffer
    call RPCEventsAll('StdinReadPost')
endf

fun! s:RPC_Events_OnBufWrite() " starting to write the whole buffer to a file
    call RPCEventsAll('BufWrite')
endf

fun! s:RPC_Events_OnBufWritePre() " starting to write the whole buffer to a file
    call RPCEventsAll('BufWritePre')
endf

fun! s:RPC_Events_OnBufWritePost() " after writing the whole buffer to a file
    call RPCEventsAll('BufWritePost')
endf

fun! s:RPC_Events_OnBufWriteCmd() " before writing the whole buffer to a file |Cmd-event|
    call RPCEventsAll('BufWriteCmd')
endf

fun! s:RPC_Events_OnFileWritePre() " starting to write part of a buffer to a file
    call RPCEventsAll('FileWritePre')
endf

fun! s:RPC_Events_OnFileWritePost() " after writing part of a buffer to a file
    call RPCEventsAll('FileWritePost')
endf

fun! s:RPC_Events_OnFileWriteCmd() " before writing part of a buffer to a file |Cmd-event|
    call RPCEventsAll('FileWriteCmd')
endf

fun! s:RPC_Events_OnFileAppendPre() " starting to append to a file
    call RPCEventsAll('FileAppendPre')
endf

fun! s:RPC_Events_OnFileAppendPost() " after appending to a file
    call RPCEventsAll('FileAppendPost')
endf

fun! s:RPC_Events_OnFileAppendCmd() " before appending to a file |Cmd-event|
    call RPCEventsAll('FileAppendCmd')
endf

fun! s:RPC_Events_OnFilterWritePre() " starting to write a file for a filter command or diff
    call RPCEventsAll('FilterWritePre')
endf

fun! s:RPC_Events_OnFilterWritePost() " after writing a file for a filter command or diff
    call RPCEventsAll('FilterWritePost')
endf

fun! s:RPC_Events_OnBufAdd() " just after adding a buffer to the buffer list
    call RPCEventsAll('BufAdd')
endf

fun! s:RPC_Events_OnBufCreate() " just after adding a buffer to the buffer list
    call RPCEventsAll('BufCreate')
endf

fun! s:RPC_Events_OnBufDelete() " before deleting a buffer from the buffer list
    call RPCEventsAll('BufDelete')
endf

fun! s:RPC_Events_OnBufWipeout() " before completely deleting a buffer
    call RPCEventsAll('BufWipeout')
endf

fun! s:RPC_Events_OnBufFilePre() " before changing the name of the current buffer
    call RPCEventsAll('BufFilePre')
endf

fun! s:RPC_Events_OnBufFilePost() " after changing the name of the current buffer
    call RPCEventsAll('BufFilePost')
endf

fun! s:RPC_Events_OnBufEnter() " after entering a buffer
    call RPCEventsAll('BufEnter')
endf

fun! s:RPC_Events_OnBufLeave() " before leaving to another buffer
    call RPCEventsAll('BufLeave')
endf

fun! s:RPC_Events_OnBufWinEnter() " after a buffer is displayed in a window
    call RPCEventsAll('BufWinEnter')
endf

fun! s:RPC_Events_OnBufWinLeave() " before a buffer is removed from a window
    call RPCEventsAll('BufWinLeave')
endf

fun! s:RPC_Events_OnBufUnload() " before unloading a buffer
    call RPCEventsAll('BufUnload')
endf

fun! s:RPC_Events_OnBufHidden() " just after a buffer has become hidden
    call RPCEventsAll('BufHidden')
endf

fun! s:RPC_Events_OnBufNew() " just after creating a new buffer
    call RPCEventsAll('BufNew')
endf

fun! s:RPC_Events_OnSwapExists() " detected an existing swap file
    call RPCEventsAll('SwapExists')
endf

fun! s:RPC_Events_OnFileType() " when the 'filetype' option has been set
    call RPCEventsAll('FileType')
endf

fun! s:RPC_Events_OnSyntax() " when the 'syntax' option has been set
    call RPCEventsAll('Syntax')
endf

fun! s:RPC_Events_OnEncodingChanged() " after the 'encoding' option has been changed
    call RPCEventsAll('EncodingChanged')
endf

fun! s:RPC_Events_OnTermChanged() " after the value of 'term' has changed
    call RPCEventsAll('TermChanged')
endf

fun! s:RPC_Events_OnOptionSet() " after setting any option
    call RPCEventsAll('OptionSet')
endf

fun! s:RPC_Events_OnVimEnter() " after doing all the startup stuff
    call RPCEventsAll('VimEnter')
endf

fun! s:RPC_Events_OnGUIEnter() " after starting the GUI successfully
    call RPCEventsAll('GUIEnter')
endf

fun! s:RPC_Events_OnGUIFailed() " after starting the GUI failed
    call RPCEventsAll('GUIFailed')
endf

fun! s:RPC_Events_OnTermResponse() " after the terminal response to |t_RV| is received
    call RPCEventsAll('TermResponse')
endf

fun! s:RPC_Events_OnQuitPre() " when using `:quit`, before deciding whether to exit
    call RPCEventsAll('QuitPre')
endf

fun! s:RPC_Events_OnExitPre() " when using a command that may make Vim exit
    call RPCEventsAll('ExitPre')
endf

fun! s:RPC_Events_OnVimLeavePre() " before exiting Vim, before writing the viminfo file
    call RPCEventsAll('VimLeavePre')
endf

fun! s:RPC_Events_OnVimLeave() " before exiting Vim, after writing the viminfo file
    call RPCEventsAll('VimLeave')
endf

fun! s:RPC_Events_OnTerminalOpen() " after a terminal buffer was created
    call RPCEventsAll('TerminalOpen')
endf

fun! s:RPC_Events_OnTerminalWinOpen() " after a terminal buffer was created in a new window
    call RPCEventsAll('TerminalWinOpen')
endf

fun! s:RPC_Events_OnFileChangedShell() " Vim notices that a file changed since editing started
    call RPCEventsAll('FileChangedShell')
endf

fun! s:RPC_Events_OnFileChangedShellPost() " After handling a file changed since editing started
    call RPCEventsAll('FileChangedShellPost')
endf

fun! s:RPC_Events_OnFileChangedRO() " before making the first change to a read-only file
    call RPCEventsAll('FileChangedRO')
endf

fun! s:RPC_Events_OnDiffUpdated() " after diffs have been updated
    call RPCEventsAll('DiffUpdated')
endf

fun! s:RPC_Events_OnDirChanged() " after the working directory has changed
    call RPCEventsAll('DirChanged')
endf

fun! s:RPC_Events_OnShellCmdPost() " after executing a shell command
    call RPCEventsAll('ShellCmdPost')
endf

fun! s:RPC_Events_OnShellFilterPost() " after filtering with a shell command
    call RPCEventsAll('ShellFilterPost')
endf

fun! s:RPC_Events_OnCmdUndefined() " a user command is used but it isn't defined
    call RPCEventsAll('CmdUndefined')
endf

fun! s:RPC_Events_OnFuncUndefined() " a user function is used but it isn't defined
    call RPCEventsAll('FuncUndefined')
endf

fun! s:RPC_Events_OnSpellFileMissing() " a spell file is used but it can't be found
    call RPCEventsAll('SpellFileMissing')
endf

fun! s:RPC_Events_OnSourcePre() " before sourcing a Vim script
    call RPCEventsAll('SourcePre')
endf

fun! s:RPC_Events_OnSourcePost() " after sourcing a Vim script
    call RPCEventsAll('SourcePost')
endf

fun! s:RPC_Events_OnSourceCmd() " before sourcing a Vim script |Cmd-event|
    call RPCEventsAll('SourceCmd')
endf

fun! s:RPC_Events_OnVimResized() " after the Vim window size changed
    call RPCEventsAll('VimResized')
endf

fun! s:RPC_Events_OnFocusGained() " Vim got input focus
    call RPCEventsAll('FocusGained')
endf

fun! s:RPC_Events_OnFocusLost() " Vim lost input focus
    call RPCEventsAll('FocusLost')
endf

fun! s:RPC_Events_OnCursorHold() " the user doesn't press a key for a while
    call RPCEventsAll('CursorHold')
endf

fun! s:RPC_Events_OnCursorHoldI() " the user doesn't press a key for a while in Insert mode
    call RPCEventsAll('CursorHoldI')
endf

fun! s:RPC_Events_OnCursorMoved() " the cursor was moved in Normal mode
    call RPCEventsAll('CursorMoved')
endf

fun! s:RPC_Events_OnCursorMovedI() " the cursor was moved in Insert mode
    call RPCEventsAll('CursorMovedI')
endf

fun! s:RPC_Events_OnWinNew() " after creating a new window
    call RPCEventsAll('WinNew')
endf

fun! s:RPC_Events_OnTabNew() " after creating a new tab page
    call RPCEventsAll('TabNew')
endf

fun! s:RPC_Events_OnTabClosed() " after closing a tab page
    call RPCEventsAll('TabClosed')
endf

fun! s:RPC_Events_OnWinEnter() " after entering another window
    call RPCEventsAll('WinEnter')
endf

fun! s:RPC_Events_OnWinLeave() " before leaving a window
    call RPCEventsAll('WinLeave')
endf

fun! s:RPC_Events_OnTabEnter() " after entering another tab page
    call RPCEventsAll('TabEnter')
endf

fun! s:RPC_Events_OnTabLeave() " before leaving a tab page
    call RPCEventsAll('TabLeave')
endf

fun! s:RPC_Events_OnCmdwinEnter() " after entering the command-line window
    call RPCEventsAll('CmdwinEnter')
endf

fun! s:RPC_Events_OnCmdwinLeave() " before leaving the command-line window
    call RPCEventsAll('CmdwinLeave')
endf

fun! s:RPC_Events_OnCmdlineChanged() " after a change was made to the command-line text
    call RPCEventsAll('CmdlineChanged')
endf

fun! s:RPC_Events_OnCmdlineEnter() " after the cursor moves to the command line
    call RPCEventsAll('CmdlineEnter')
endf

fun! s:RPC_Events_OnCmdlineLeave() " before the cursor leaves the command line
    call RPCEventsAll('CmdlineLeave')
endf

fun! s:RPC_Events_OnInsertEnter() " starting Insert mode
    call RPCEventsAll('InsertEnter')
endf

fun! s:RPC_Events_OnInsertChange() " when typing <Insert> while in Insert or Replace mode
    call RPCEventsAll('InsertChange')
endf

fun! s:RPC_Events_OnInsertLeave() " when leaving Insert mode
    call RPCEventsAll('InsertLeave')
endf

fun! s:RPC_Events_OnInsertCharPre() " when a character was typed in Insert mode, before
    call RPCEventsAll('InsertCharPre')
endf

fun! s:RPC_Events_OnTextChanged() " after a change was made to the text in Normal mode
    call RPCEventsAll('TextChanged')
endf

fun! s:RPC_Events_OnTextChangedI() " after a change was made to the text in Insert mode when popup menu is not visible

    call RPCEventsAll('TextChangedI')
endf

fun! s:RPC_Events_OnTextChangedP() " after a change was made to the text in Insert mode when popup menu visible
    call RPCEventsAll('TextChangedP')
endf

fun! s:RPC_Events_OnTextYankPost() " after text has been yanked or deleted
    call RPCEventsAll('TextYankPost')
endf

fun! s:RPC_Events_OnSafeState() " nothing pending, going to wait for the user to type a character
    call RPCEventsAll('SafeState')
endf

fun! s:RPC_Events_OnSafeStateAgain() " repeated SafeState
    call RPCEventsAll('SafeStateAgain')
endf

fun! s:RPC_Events_OnColorSchemePre() " before loading a color scheme
    call RPCEventsAll('ColorSchemePre')
endf

fun! s:RPC_Events_OnColorScheme() " after loading a color scheme
    call RPCEventsAll('ColorScheme')
endf

fun! s:RPC_Events_OnRemoteReply() " a reply from a server Vim was received
    call RPCEventsAll('RemoteReply')
endf

fun! s:RPC_Events_OnQuickFixCmdPre() " before a quickfix command is run
    call RPCEventsAll('QuickFixCmdPre')
endf

fun! s:RPC_Events_OnQuickFixCmdPost() " after a quickfix command is run
    call RPCEventsAll('QuickFixCmdPost')
endf

fun! s:RPC_Events_OnSessionLoadPost() " after loading a session file
    call RPCEventsAll('SessionLoadPost')
endf

fun! s:RPC_Events_OnMenuPopup() " just before showing the popup menu
    call RPCEventsAll('MenuPopup')
endf

fun! s:RPC_Events_OnCompleteChanged() " after Insert mode completion menu changed
    call RPCEventsAll('CompleteChanged')
endf

fun! s:RPC_Events_OnCompleteDonePre() " after Insert mode completion is done, before clearing info
    call RPCEventsAll('CompleteDonePre')
endf

fun! s:RPC_Events_OnCompleteDone() " after Insert mode completion is done, after clearing info
    call RPCEventsAll('CompleteDone')
endf

fun! s:RPC_Events_OnUser() " to be used in combination with ':doautocmd'
    call RPCEventsAll('User')
endf

fun! s:RPC_Events_OnSigUSR1() " after the SIGUSR1 signal has been detected
    call RPCEventsAll('SigUSR1')
endf
"}}}

fun! s:InitEvent()
"{{{
  augroup rcp_e
    autocmd!
    " autocmd BufNewFile * call s:RPC_Events_OnBufNewFile()
    " autocmd BufReadPre * call s:RPC_Events_OnBufReadPre()
    " autocmd BufRead * call s:RPC_Events_OnBufRead()
    " autocmd BufReadPost * call s:RPC_Events_OnBufReadPost()
    " autocmd BufReadCmd * call s:RPC_Events_OnBufReadCmd()
    " autocmd FileReadPre * call s:RPC_Events_OnFileReadPre()
    " autocmd FileReadPost * call s:RPC_Events_OnFileReadPost()
    " autocmd FileReadCmd * call s:RPC_Events_OnFileReadCmd()
    " autocmd FilterReadPre * call s:RPC_Events_OnFilterReadPre()
    " autocmd FilterReadPost * call s:RPC_Events_OnFilterReadPost()
    " autocmd StdinReadPre * call s:RPC_Events_OnStdinReadPre()
    " autocmd StdinReadPost * call s:RPC_Events_OnStdinReadPost()
    " autocmd BufWrite * call s:RPC_Events_OnBufWrite()
    " autocmd BufWritePre * call s:RPC_Events_OnBufWritePre()
    " autocmd BufWritePost * call s:RPC_Events_OnBufWritePost()
    " autocmd BufWriteCmd * call s:RPC_Events_OnBufWriteCmd()
    " autocmd FileWritePre * call s:RPC_Events_OnFileWritePre()
    " autocmd FileWritePost * call s:RPC_Events_OnFileWritePost()
    " autocmd FileWriteCmd * call s:RPC_Events_OnFileWriteCmd()
    " autocmd FileAppendPre * call s:RPC_Events_OnFileAppendPre()
    " autocmd FileAppendPost * call s:RPC_Events_OnFileAppendPost()
    " autocmd FileAppendCmd * call s:RPC_Events_OnFileAppendCmd()
    " autocmd FilterWritePre * call s:RPC_Events_OnFilterWritePre()
    " autocmd FilterWritePost * call s:RPC_Events_OnFilterWritePost()
    " autocmd BufAdd * call s:RPC_Events_OnBufAdd()
    autocmd BufCreate * call s:RPC_Events_OnBufCreate()
    autocmd BufDelete * call s:RPC_Events_OnBufDelete()
    " autocmd BufWipeout * call s:RPC_Events_OnBufWipeout()
    " autocmd BufFilePre * call s:RPC_Events_OnBufFilePre()
    " autocmd BufFilePost * call s:RPC_Events_OnBufFilePost()
    autocmd BufEnter * call s:RPC_Events_OnBufEnter()
    autocmd BufLeave * call s:RPC_Events_OnBufLeave()
    autocmd BufWinEnter * call s:RPC_Events_OnBufWinEnter()
    autocmd BufWinLeave * call s:RPC_Events_OnBufWinLeave()
    autocmd BufUnload * call s:RPC_Events_OnBufUnload()
    autocmd BufHidden * call s:RPC_Events_OnBufHidden()
    autocmd BufNew * call s:RPC_Events_OnBufNew()
    " autocmd SwapExists * call s:RPC_Events_OnSwapExists()
    autocmd FileType * call s:RPC_Events_OnFileType()
    " autocmd Syntax * call s:RPC_Events_OnSyntax()
    autocmd EncodingChanged * call s:RPC_Events_OnEncodingChanged()
    " autocmd TermChanged * call s:RPC_Events_OnTermChanged()
    " autocmd OptionSet * call s:RPC_Events_OnOptionSet()
    autocmd VimEnter * call s:RPC_Events_OnVimEnter()
    autocmd GUIEnter * call s:RPC_Events_OnGUIEnter()
    autocmd GUIFailed * call s:RPC_Events_OnGUIFailed()
    " autocmd TermResponse * call s:RPC_Events_OnTermResponse()
    autocmd QuitPre * call s:RPC_Events_OnQuitPre()
    autocmd ExitPre * call s:RPC_Events_OnExitPre()
    " autocmd VimLeavePre * call s:RPC_Events_OnVimLeavePre()
    autocmd VimLeave * call s:RPC_Events_OnVimLeave()
    autocmd TerminalOpen * call s:RPC_Events_OnTerminalOpen()
    autocmd TerminalWinOpen * call s:RPC_Events_OnTerminalWinOpen()
    " autocmd FileChangedShell * call s:RPC_Events_OnFileChangedShell()
    " autocmd FileChangedShellPost * call s:RPC_Events_OnFileChangedShellPost()
    autocmd FileChangedRO * call s:RPC_Events_OnFileChangedRO()
    " autocmd DiffUpdated * call s:RPC_Events_OnDiffUpdated()
    " autocmd DirChanged * call s:RPC_Events_OnDirChanged()
    " autocmd ShellCmdPost * call s:RPC_Events_OnShellCmdPost()
    " autocmd ShellFilterPost * call s:RPC_Events_OnShellFilterPost()
    " autocmd CmdUndefined * call s:RPC_Events_OnCmdUndefined()
    " autocmd FuncUndefined * call s:RPC_Events_OnFuncUndefined()
    " autocmd SpellFileMissing * call s:RPC_Events_OnSpellFileMissing()
    " autocmd SourcePre * call s:RPC_Events_OnSourcePre()
    " autocmd SourcePost * call s:RPC_Events_OnSourcePost()
    " autocmd SourceCmd * call s:RPC_Events_OnSourceCmd()
    " autocmd VimResized * call s:RPC_Events_OnVimResized()
    " autocmd FocusGained * call s:RPC_Events_OnFocusGained()
    " autocmd FocusLost * call s:RPC_Events_OnFocusLost()
    autocmd CursorHold * call s:RPC_Events_OnCursorHold()
    autocmd CursorHoldI * call s:RPC_Events_OnCursorHoldI()
    autocmd CursorMoved * call s:RPC_Events_OnCursorMoved()
    autocmd CursorMovedI * call s:RPC_Events_OnCursorMovedI()
    " autocmd WinNew * call s:RPC_Events_OnWinNew()
    autocmd TabNew * call s:RPC_Events_OnTabNew()
    " autocmd TabClosed * call s:RPC_Events_OnTabClosed()
    autocmd WinEnter * call s:RPC_Events_OnWinEnter()
    autocmd WinLeave * call s:RPC_Events_OnWinLeave()
    autocmd TabEnter * call s:RPC_Events_OnTabEnter()
    autocmd TabLeave * call s:RPC_Events_OnTabLeave()
    " autocmd CmdwinEnter * call s:RPC_Events_OnCmdwinEnter()
    " autocmd CmdwinLeave * call s:RPC_Events_OnCmdwinLeave()
    " autocmd CmdlineChanged * call s:RPC_Events_OnCmdlineChanged()
    " autocmd CmdlineEnter * call s:RPC_Events_OnCmdlineEnter()
    " autocmd CmdlineLeave * call s:RPC_Events_OnCmdlineLeave()
    autocmd InsertEnter * call s:RPC_Events_OnInsertEnter()
    autocmd InsertChange * call s:RPC_Events_OnInsertChange()
    autocmd InsertLeave * call s:RPC_Events_OnInsertLeave()
    autocmd InsertCharPre * call s:RPC_Events_OnInsertCharPre()
    autocmd TextChanged * call s:RPC_Events_OnTextChanged()
    autocmd TextChangedI * call s:RPC_Events_OnTextChangedI()
    autocmd TextChangedP * call s:RPC_Events_OnTextChangedP()
    " autocmd TextYankPost * call s:RPC_Events_OnTextYankPost()
    " autocmd SafeState * call s:RPC_Events_OnSafeState()
    " autocmd SafeStateAgain * call s:RPC_Events_OnSafeStateAgain()
    " autocmd ColorSchemePre * call s:RPC_Events_OnColorSchemePre()
    " autocmd ColorScheme * call s:RPC_Events_OnColorScheme()
    " autocmd RemoteReply * call s:RPC_Events_OnRemoteReply()
    " autocmd QuickFixCmdPre * call s:RPC_Events_OnQuickFixCmdPre()
    " autocmd QuickFixCmdPost * call s:RPC_Events_OnQuickFixCmdPost()
    " autocmd SessionLoadPost * call s:RPC_Events_OnSessionLoadPost()
    " autocmd MenuPopup * call s:RPC_Events_OnMenuPopup()
    autocmd CompleteChanged * call s:RPC_Events_OnCompleteChanged()
    " autocmd CompleteDonePre * call s:RPC_Events_OnCompleteDonePre()
    autocmd CompleteDone * call s:RPC_Events_OnCompleteDone()
    " autocmd User * call s:RPC_Events_OnUser()
    " autocmd SigUSR1 * call s:RPC_Events_OnSigUSR1()
  augroup END
"}}}
endf

call s:InitEvent()
