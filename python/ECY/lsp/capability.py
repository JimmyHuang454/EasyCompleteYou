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
        "configuration": False
    },
    "textDocument": {
        "synchronization": {
            "dynamicRegistration": False,
            "willSave": True,
            "willSaveWaitUntil": True,
            "didSave": True
        },
        "completion": {
            "dynamicRegistration": False,
            "completionItem": {
                "snippetSupport": True,
                "commitCharactersSupport": False,
                "documentationFormat": ["plaintext"],
                "deprecatedSupport": False,
                "preselectSupport": False
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
            }
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
            "rangeLimit": 100,
            "lineFoldingOnly": True
        },
        "semanticTokens": {
            "requests": {
                "range": True,
                "full": True
            },
            "tokenTypes": [],
            "formats": ['relative'],
            "overlappingTokenSupport": True,
            "multilineTokenSupport": True,
            "tokenModifiers": []
        }
    },
    "experimental": None
}
