" syn match ECY_diagnostics_erro_hi  display '^ECY_diagnostics_erro'
" syn match ECY_diagnostics_warn_hi  display '^ECY_diagnostics_warn'

" exe printf("syn match ECY_signature_help_activeParameter  display '%s'", g:ECY_signature_help_activeParameter)
if g:ECY_signature_help_activeSignature != ''
  exe printf("syn match ECY_signature_help_activeSignature  display '%s'", g:ECY_signature_help_activeSignature)
endif

hi def link ECY_signature_help_activeParameter Search
hi def link ECY_signature_help_activeSignature Search
