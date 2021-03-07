if g:ECY_signature_help_activeParameter != ''
  exe printf("syn match ECY_signature_help_activeParameter  display '%s'", g:ECY_signature_help_activeParameter)
endif

if g:ECY_signature_help_activeSignature != ''
  exe printf("syn match ECY_signature_help_activeSignature  display '%s'", g:ECY_signature_help_activeSignature)
endif

hi def link ECY_signature_help_activeParameter Title
hi def link ECY_signature_help_activeSignature Search
