#!/usr/bin/env python3
"""Native HarmonyOS demo QA. Only operates the named local emulator."""
import subprocess,json,sys,re,time
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'demo-verification/live-flow'
HDC='/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
def run(*args):
 r=subprocess.run([HDC,'-t','127.0.0.1:5555',*args],capture_output=True,text=True)
 if r.returncode or '[Fail]' in r.stdout:raise RuntimeError(r.stdout+r.stderr)
 return r.stdout
def nodes(x):
 if isinstance(x,dict):
  if 'attributes' in x:yield x['attributes']
  for v in x.values():yield from nodes(v)
 elif isinstance(x,list):
  for v in x:yield from nodes(v)
def dump(name='current'):
 run('shell','uitest','dumpLayout','-p','/data/local/tmp/fridge-demo-ui.json')
 run('file','recv','/data/local/tmp/fridge-demo-ui.json',str(OUT/(name+'.json')))
 return list(nodes(json.loads((OUT/(name+'.json')).read_text())))
def report(items):
 for a in items:
  label=a.get('text') or a.get('description')
  if label:print(json.dumps({k:a.get(k) for k in ['text','description','bounds','type','clickable']},ensure_ascii=False))
a=sys.argv[1:]
if a[0]=='capture':
 time.sleep(.55)
 name=a[1];run('shell','uitest','screenCap','-p','/data/local/tmp/fridge-demo-ui.png');run('file','recv','/data/local/tmp/fridge-demo-ui.png',str(OUT/(name+'.png')));report(dump(name))
elif a[0]=='dump':report(dump())
elif a[0]=='tap':
 items=dump();matches=[n for n in items if a[1] in [n.get('text'),n.get('description'),n.get('key')]]
 if len(matches)>1:
  clickable=[n for n in matches if n.get('clickable')=='true']
  if len(clickable)==1:matches=clickable
 if len(matches)!=1:raise RuntimeError('Expected one match: '+str(matches))
 v=list(map(int,re.findall(r'\d+',matches[0]['bounds'])));print(run('shell','uitest','uiInput','click',str((v[0]+v[2])//2),str((v[1]+v[3])//2)));time.sleep(.5);report(dump())
elif a[0]=='click':print(run('shell','uitest','uiInput','click',a[1],a[2]));time.sleep(.5);report(dump())
elif a[0]=='back':print(run('shell','uitest','uiInput','keyEvent','Back'));time.sleep(.5);report(dump())
