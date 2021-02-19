syn match ECY_diagnostics_erro_hi  display '^ECY_diagnostics_erro'
syn match ECY_diagnostics_warn_hi  display '^ECY_diagnostics_warn'
syn match ECY_diagnostics_nr  display '(.*)'
syn match ECY_diagnostics_text  display '^(.*)'
syn match ECY_diagnostics_linenr  display '\[.*\]'

hi def link ECY_diagnostics_erro_hi Error
hi def link ECY_diagnostics_warn_hi TODO
hi def link ECY_diagnostics_text String
hi def link ECY_diagnostics_nr Search
hi def link ECY_diagnostics_linenr CursorLineNr
