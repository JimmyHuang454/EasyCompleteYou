CAPABILITY = {
    "workspace": {
        "applyEdit": True,
        "workspaceEdit": {
            "documentChanges": True,
            "resourceOperations": ["create", "rename", "delete"],
            "failureHandling": "abort",
            "normalizesLineEndings": False,
        },
        "didChangeConfiguration": {
            "dynamicRegistration": False
        },
        "didChangeWatchedFiles": {
            "dynamicRegistration": False
        },
        "symbol": {
            "dynamicRegistration": False,
            "symbolKind": {
                "valueSet": [
                    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
                    18, 19, 20, 21, 22, 23, 24, 25, 26
                ]
            }
        },
        "executeCommand": {
            "dynamicRegistration": False
        },
        "workspaceFolders": True,
        "configuration": False,
        "semanticTokens": {
            'refreshSupport': False
        }
    },
    "textDocument": {
        "synchronization": {
            "dynamicRegistration": False,
            "willSave": False,
            "willSaveWaitUntil": False,
            "didSave": True
        },
        "completion": {
            "dynamicRegistration": False,
            "completionItem": {
                "snippetSupport": True,
                "commitCharactersSupport": False,
                "documentationFormat": ["plaintext"],
                "deprecatedSupport": False,
                "insertReplaceSupport": True,
                "preselectSupport": False
            },
            "resolveSupport": {
                "properties": ['documentation', 'detail']
            },
            "completionItemKind": {
                "valueSet": []
            },
            "contextSupport": False
        },
        "hover": {
            "dynamicRegistration": False,
            "contentFormat": []
        },
        "signatrueHelp": {
            "dynamicRegistration": False,
            "signatrueInformation": {
                "documentationFormat": ["plaintext"],
                "parameterInformation": {
                    "labelOffsetSupport": True
                }
            }
        },
        "references": {
            "dynamicRegistration": False
        },
        "documentHighlight": {
            "dynamicRegistration": False
        },
        "documentSymbol": {
            "dynamicRegistration": False,
            "symbolKind": {
                "valueSet": [
                    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
                    18, 19, 20, 21, 22, 23, 24, 25, 26
                ]
            },
            "hierarchicalDocumentSymbolSupport": True
        },
        "formatting": {
            "dynamicRegistration": False
        },
        "rangeFormatting": {
            "dynamicRegistration": False
        },
        "onTypeFormatting": {
            "dynamicRegistration": False
        },
        "declaration": {
            "dynamicRegistration": False,
            "linkSupport": True
        },
        "definition": {
            "dynamicRegistration": False,
            "linkSupport": True
        },
        "typeDefinition": {
            "dynamicRegistration": False,
            "linkSupport": True
        },
        "implementation": {
            "dynamicRegistration": False,
            "linkSupport": True
        },
        "codeAction": {
            "dynamicRegistration": False,
            "codeActionLiteralSupport": {
                "codeActionKind": {
                    "valueSet": [
                        "quickfix", "refactor", "refactor.extract",
                        "refactor.inline", "refactor.rewrite", "source",
                        "source.organizeImports"
                    ]
                }
            },
            "isPreferredSupport": True,
            "disabledSupport": True,
            "dataSupport": True,
        },
        "codeLens": {
            "dynamicRegistration": False
        },
        "documentLink": {
            "dynamicRegistration": False
        },
        "colorProvider": {
            "dynamicRegistration": False
        },
        "rename": {
            "dynamicRegistration": False,
            "prepareSupport": True
        },
        "publishDiagnostics": {
            "relatedInformation": True,
            "versionSupport": True,
            "tagSupport": {
                "valueSet": [1, 2]
            },
            "codeDescriptionSupport": True,
            "dataSupport": True
        },
        "foldingRange": {
            "dynamicRegistration": False,
            "lineFoldingOnly": False
        },
        "semanticTokens": {
            "requests": {
                "range": True,
                "full": {
                    'delta': False
                }
            },
            "tokenTypes": [],
            "formats": ['relative'],
            "overlappingTokenSupport": False,
            "multilineTokenSupport": False,
            "tokenModifiers": []
        }
    },
    "experimental": None
}
