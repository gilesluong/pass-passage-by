import json, tempfile, subprocess, sys
from pathlib import Path
from mcp_server import Bridge
with tempfile.TemporaryDirectory() as root:
    b=Bridge(root)
    assert b.call('ppb_list_context',{})==[]
    r=b.call('ppb_submit_writing',{'title':'Unicode','text':'😀 hello. hello.','notes':[{'quote':'hello','occurrence':1,'label':'Word','body':'Exact second occurrence.'}]})
    d=json.loads(Path(r['path']).read_text());assert d['annotations'][0]['start']==10
    assert b.call('ppb_list_context',{})==[], 'Inbox is not implicitly shared'
    shared=Path(root)/'Shared';shared.mkdir();(shared/'test.json').write_text(json.dumps(d))
    assert b.call('ppb_read_context',{'id':'test'})['document']['title']=='Unicode'
    for args in [{'id':'../Inbox/test'},{'id':'unknown'}]:
        try: b.call('ppb_read_context',args);raise AssertionError('Unsafe read allowed')
        except ValueError: pass
    before=list((Path(root)/'Inbox').glob('*'))
    try: b.call('ppb_submit_writing',{'title':'Invalid','text':'hello','notes':[{'quote':'missing','label':'Bad','body':'Bad'}]});raise AssertionError('Invalid quote accepted')
    except ValueError: pass
    assert list((Path(root)/'Inbox').glob('*'))==before
    msgs=[{'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2025-06-18'}},{'jsonrpc':'2.0','method':'notifications/initialized'},{'jsonrpc':'2.0','id':2,'method':'tools/list'}]
    p=subprocess.run([sys.executable,str(Path(__file__).with_name('mcp_server.py')),'--root',root],input=''.join(json.dumps(m)+'\n' for m in msgs),text=True,capture_output=True,check=True)
    responses=[json.loads(l) for l in p.stdout.splitlines()];assert len(responses)==2 and len(responses[1]['result']['tools'])==3
print('PASS: MCP handshake, tool discovery, scoped context, Unicode anchoring, invalid quote rejection, non-overwriting Inbox')
