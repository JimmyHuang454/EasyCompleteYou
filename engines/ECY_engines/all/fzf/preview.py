import time
import xmlrpc.client
import argparse
import base64
import sys
import io

sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8')
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

parser = argparse.ArgumentParser(description='preview for AltF')
parser.add_argument('--line', help='seleted item.')
parser.add_argument('--event_id', help='context')
g_args = parser.parse_args()

fzf_rpc = xmlrpc.client.ServerProxy("http://127.0.0.1:%s/" % '4563',
                                    allow_none=True)


def base64ToString(b):
    return base64.b64decode(b).decode('utf-8')


def stringToBase64(s):
    return base64.b64encode(s.encode('utf-8'))


res = fzf_rpc.preview({
    'callback_name': 'Preview',
    'id': g_args.event_id,
    'line': g_args.line
})

res = base64ToString(bytes(res, encoding='utf-8'))
print(res)
