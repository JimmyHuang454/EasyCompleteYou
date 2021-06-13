from workspace_edit import *

test_uir = "C:/Users/qwer/Desktop/vimrc/myproject/test/uifv2ray/action_proxy/golang/main.go"
workspace_edit_test = {
    "documentChanges": [{
        "textDocument": {
            "version": 10,
            "uri": test_uir
        },
        "edits": [{
            "range": {
                "start": {
                    "line": 6,
                    "character": 2
                },
                "end": {
                    "line": 6,
                    "character": 2
                }
            },
            "newText": ""
        }, {
            "range": {
                "start": {
                    "line": 6,
                    "character": 2
                },
                "end": {
                    "line": 6,
                    "character": 2
                }
            },
            "newText": "fmt\"\n\t\""
        }, {
            "range": {
                "start": {
                    "line": 10,
                    "character": 0
                },
                "end": {
                    "line": 10,
                    "character": 0
                }
            },
            "newText": "\t\"net/http\"\n"
        }, {
            "range": {
                "start": {
                    "line": 16,
                    "character": 2
                },
                "end": {
                    "line": 16,
                    "character": 6
                }
            },
            "newText": ""
        }, {
            "range": {
                "start": {
                    "line": 16,
                    "character": 6
                },
                "end": {
                    "line": 16,
                    "character": 6
                }
            },
            "newText": "sync"
        }, {
            "range": {
                "start": {
                    "line": 17,
                    "character": 0
                },
                "end": {
                    "line": 20,
                    "character": 0
                }
            },
            "newText": ""
        }, {
            "range": {
                "start": {
                    "line": 20,
                    "character": 2
                },
                "end": {
                    "line": 20,
                    "character": 4
                }
            },
            "newText": ""
        }, {
            "range": {
                "start": {
                    "line": 20,
                    "character": 5
                },
                "end": {
                    "line": 20,
                    "character": 5
                }
            },
            "newText": "ime"
        }, {
            "range": {
                "start": {
                    "line": 20,
                    "character": 6
                },
                "end": {
                    "line": 20,
                    "character": 6
                }
            },
            "newText": "\n"
        }, {
            "range": {
                "start": {
                    "line": 21,
                    "character": 32
                },
                "end": {
                    "line": 23,
                    "character": 6
                }
            },
            "newText": ""
        }]
    }]
}
res = Apply(workspace_edit_test)
res = res[test_uir]['text']
print('\n'.join(res))
